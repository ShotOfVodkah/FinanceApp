//
//  AnalysisViewModel.swift
//  Finance
//
//  Created by Stepan Polyakov on 08.07.2025.
//
import Foundation

final class AnalysisViewModel {
    
    enum SortType: String, CaseIterable {
        case date = "Дата"
        case amount = "Сумма"
    }

    private(set) var items: [(Transaction, Category)] = []
    private(set) var total: Decimal = 0
    private(set) var сurrencySymbol: String = "₽"

    var sortType: SortType = .date
    var from: Date {
        didSet {
            if to < from {
                to = Calendar.current.endOfDay(for: from)
            }
        }
    }

    var to: Date {
        didSet {
            to = Calendar.current.endOfDay(for: to)
            if from > to {
                from = Calendar.current.startOfDay(for: to)
            }
        }
    }

    let transactionService: TransactionsService
    let categoriesService: CategoriesService
    let bankAccountsService: BankAccountsService
    let direction: Direction

    var onDatesUpdated: (() -> Void)?
    var onDataLoaded: (() -> Void)?

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

        let now = Date()
        self.to = Calendar.current.endOfDay(for: now)
        self.from = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .month, value: -1, to: now)!)
    }

    func updateFromDate(_ date: Date) {
        from = Calendar.current.startOfDay(for: date)
        onDatesUpdated?()
        loadData()
    }

    func updateToDate(_ date: Date) {
        to = date
        onDatesUpdated?()
        loadData()
    }

    func updateSortType(index: Int) {
        guard index < SortType.allCases.count else { return }
        sortType = SortType.allCases[index]
        sortItems()
        onDataLoaded?()
    }

    func loadData() {
        Task {
            items = []
            
            async let transactions = transactionService.getTransactions(from: from, to: to)
            async let categories = categoriesService.getSpecific(dir: direction)
            async let account = bankAccountsService.getAccount()
                
            let (loadedTransactions, loadedCategories, bankAccount) = await (transactions, categories, account)
                
            var newItems: [(Transaction, Category)] = []
            var newTotal: Decimal = 0
                
            for transaction in loadedTransactions {
                if let category = loadedCategories.first(where: { $0.id == transaction.categoryId }) {
                    newItems.append((transaction, category))
                    newTotal += transaction.amount
                }
            }

            await MainActor.run {
                if let currency = Currency(rawValue: bankAccount.currency) {
                    self.сurrencySymbol = currency.symbol
                }

                self.items = newItems
                self.total = newTotal
                self.sortItems()
                self.onDataLoaded?()
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
}


extension Calendar {
    func startOfDay(for date: Date) -> Date {
        return self.date(bySettingHour: 0, minute: 0, second: 0, of: date)!
    }
    
    func endOfDay(for date: Date) -> Date {
        return self.date(bySettingHour: 23, minute: 59, second: 59, of: date)!
    }
}
