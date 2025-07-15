//
//  HistoryViewModel.swift
//  Finance
//
//  Created by Stepan Polyakov on 17.06.2025.
//

import Foundation

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var items: [(Transaction, Category)] = []
    @Published var total: Decimal = 0
    @Published var from: Date
    @Published var to: Date
    @Published var symbol: String = ""
    @Published var selectedTransaction: (Transaction, Category)? = nil
    @Published var sheet = false

    @Published var isLoading = false
    @Published var error: String?

    @Published var selectedSope: FilterType = .date

    enum FilterType: String, CaseIterable {
        case date = "Дата"
        case amount = "Сумма"
    }

    var filteredItems: [(Transaction, Category)] {
        switch selectedSope {
        case .date:
            return items.sorted(by: { $0.0.transactionDate > $1.0.transactionDate })
        case .amount:
            return items.sorted(by: { $0.0.amount > $1.0.amount })
        }
    }

    let transactionService: TransactionsService
    let categoriesService: CategoriesService
    let bankAccountService: BankAccountsService
    let direction: Direction

    init(transactionService: TransactionsService, categoriesService: CategoriesService, direction: Direction, bankAccountService: BankAccountsService) {
        self.categoriesService = categoriesService
        self.transactionService = transactionService
        self.direction = direction
        
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        self.to = calendar.date(bySettingHour: 23, minute: 59, second: 0, of: Date())!
        self.from = calendar.startOfDay(for: Calendar.current.date(byAdding: .month, value: -1, to: Date())!)
        self.bankAccountService = bankAccountService
    }

    func load() async {
        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            items = []
            total = 0
            
            async let transactionsTask = transactionService.getTransactions(from: from, to: to)
            async let categoriesTask = categoriesService.getSpecific(dir: direction)
            async let accountTask = bankAccountService.getAccount()
            
            let (transactions, categories, account) = try await (transactionsTask, categoriesTask, accountTask)
            
            for transaction in transactions {
                if let category = categories.first(where: { $0.id == transaction.categoryId }) {
                    items.append((transaction, category))
                    total += transaction.amount
                }
            }
            
            symbol = Currency(rawValue: account.currency)?.symbol ?? ""
        } catch is CancellationError {
            print("Вышел с экрана, задача отменилась")
        } catch {
            self.error = error.localizedDescription
        }
    }

    func check_date(to_changed: Bool) {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        var from_date = calendar.startOfDay(for: from)
        var to_date = calendar.startOfDay(for: to)

        guard (to_changed && from_date > to_date) || (!to_changed && to_date < from_date) else { return }

        if from_date > to_date && to_changed {
            from_date = to_date
        } else if to_date < from_date {
            to_date = from_date
        }

        self.from = from_date
        self.to = calendar.date(bySettingHour: 23, minute: 59, second: 0, of: to_date)!
    }
}

