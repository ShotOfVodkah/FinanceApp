//
//  IncomeViewModel.swift
//  Finance
//
//  Created by Stepan Polyakov on 16.06.2025.
//

import Foundation

@MainActor
final class TransactionsListViewModel: ObservableObject {
    @Published var items: [(Transaction, Category)] = []
    @Published var total: Decimal = 0
    @Published var symbol: String = ""
    @Published var selectedTransaction: (Transaction, Category)? = nil
    @Published var sheet = false

    @Published var isLoading = false
    @Published var error: String?
    
    private var loadingTask: Task<Void, Never>?

    var directionText: String {
        switch direction {
        case .income: return "Доходы сегодня"
        case .outcome: return "Расходы сегодня"
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
        self.bankAccountService = bankAccountService
    }

    func load() async {
        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            items = []
            total = 0
            
            var calendar = Calendar.current
            calendar.timeZone = TimeZone.current
            let start = calendar.startOfDay(for: Date())
            let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: Date())!
            let transactions = try await transactionService.getTransactions(from: start, to: end)
            let categories = try await categoriesService.getSpecific(dir: direction)
            let account = try await bankAccountService.getAccount()
                    
            var processedItems: [(Transaction, Category)] = []
            var processedTotal: Decimal = 0
                    
            for transaction in transactions {
                if let category = categories.first(where: { $0.id == transaction.categoryId }) {
                    processedItems.append((transaction, category))
                    processedTotal += transaction.amount
                }
            }
                    
            await MainActor.run {
                self.items = processedItems
                self.total = processedTotal
                self.symbol = Currency(rawValue: account.currency)?.symbol ?? "$"
            }
        } catch is CancellationError {
            print("Вышел с экрана, задача отменилась")
        } catch let error as NetworkError {
            switch error {
                case .noInternet:
                    print("интернет off")
                default:
                    self.error = error.localizedDescription
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

