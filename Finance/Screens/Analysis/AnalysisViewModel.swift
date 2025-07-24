//
//  AnalysisViewModel.swift
//  Finance
//
//  Created by Stepan Polyakov on 08.07.2025.
//
import Foundation
import PieChart

@MainActor
final class AnalysisViewModel: ObservableObject {
    
    enum SortType: String, CaseIterable {
        case date = "Дата"
        case amount = "Сумма"
    }
    
    var onDatesUpdated: (() -> Void)?
    var onDataLoaded: (() -> Void)?

    @Published private(set) var items: [(Transaction, Category)] = []
    @Published private(set) var total: Decimal = 0
    @Published private(set) var сurrencySymbol: String = "₽"
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var sortType: SortType = .date
    @Published var from: Date
    @Published var to: Date

    let transactionService: TransactionsService
    let categoriesService: CategoriesService
    let bankAccountsService: BankAccountsService
    let direction: Direction

    init(
        transactionService: TransactionsService,
        categoriesService: CategoriesService,
        bankAccountsService: BankAccountsService,
        direction: Direction
    ) {
        self.transactionService = transactionService
        self.categoriesService = categoriesService
        self.bankAccountsService = bankAccountsService
        self.direction = direction

        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        let now = Date()
        self.to = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now)!
        let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
        self.from = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: oneMonthAgo)!
    }

    func updateFromDate(_ date: Date) {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        let newFrom = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: date)!
        from = newFrom
        if to < from {
            to = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: from)!
        }
        loadData()
    }

    func updateToDate(_ date: Date) {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        let newTo = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date)!
        to = newTo
        if from > to {
            from = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: to)!
        }
        loadData()
    }

    func updateSortType(index: Int) {
        guard index < SortType.allCases.count else { return }
        sortType = SortType.allCases[index]
        sortItems()
        onDataLoaded?()
    }

    func loadData() {
        isLoading = true
        error = nil
        items = []
        total = 0
        onDataLoaded?()

        Task {
            defer {
                isLoading = false
                onDataLoaded?()
            }
            
            do {
                async let transactions = transactionService.getTransactions(from: from, to: to)
                async let categories = categoriesService.getSpecific(dir: direction)
                async let account = bankAccountsService.getAccount()

                let (loadedTransactions, loadedCategories, bankAccount) = try await (transactions, categories, account)

                var newItems: [(Transaction, Category)] = []
                var newTotal: Decimal = 0

                for transaction in loadedTransactions {
                    if let category = loadedCategories.first(where: { $0.id == transaction.categoryId }) {
                        newItems.append((transaction, category))
                        newTotal += transaction.amount
                    }
                }

                if let currency = Currency(rawValue: bankAccount.currency) {
                    self.сurrencySymbol = currency.symbol
                }

                self.items = newItems
                self.total = newTotal
                self.sortItems()
            } catch is CancellationError {
                print("Вышел с экрана, задача отменилась")
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    func percentage(for transaction: Transaction) -> String {
        guard total != 0 else { return "0%" }
        let percent = (transaction.amount as NSDecimalNumber)
            .dividing(by: total as NSDecimalNumber)
            .multiplying(by: 100)
            .doubleValue
        return String(format: "%.1f%%", percent)
    }

    private func sortItems() {
        switch sortType {
        case .date:
            items.sort { $0.0.transactionDate > $1.0.transactionDate }
        case .amount:
            items.sort { $0.0.amount > $1.0.amount }
        }
    }
    
    func pieChartEntities() -> [Entity] {
        guard total > 0 else { return [] }
        
        var categorySums: [String: Decimal] = [:]
        
        for (transaction, category) in items {
            categorySums[category.name] = (categorySums[category.name] ?? 0) + transaction.amount
        }
        
        return categorySums.map { name, sum in
            let percentage = (sum / total) * 100
            let roundedPercentage = percentage.rounded(toPlaces: 1)
            return Entity(value: roundedPercentage, label: name)
        }.sorted { $0.value > $1.value }
    }
}

extension Decimal {
    func rounded(toPlaces places: Int) -> Decimal {
        var result = Decimal()
        var localCopy = self
        NSDecimalRound(&result, &localCopy, places, .plain)
        return result
    }
}
