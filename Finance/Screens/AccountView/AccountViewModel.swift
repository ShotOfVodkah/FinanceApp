//
//  BankAccountViewModel.swift
//  Finance
//
//  Created by Stepan Polyakov on 23.06.2025.
//

import Foundation
import Charts

struct BalanceBar: Identifiable {
    let id = UUID()
    let date: Date
    let balance: Decimal
}

@MainActor
final class AccountViewModel: ObservableObject {
    private let bankAccountService: BankAccountsService
    private let transactionService: TransactionsService
    private let categoriesService: CategoriesService

    @Published var account: BankAccount?
    @Published var isLoading = false
    @Published var error: String?
    @Published var balances: [BalanceBar] = []

    var currency: String {
        guard let code = account?.currency,
              let currency = Currency(rawValue: code) else { return "" }
        return currency.symbol
    }
    
    @Published var localBalanceText: String = ""
    @Published var formattedBalanceText: String = ""
    @Published var localCurrency: Currency = .rub

    var currencyString: String {
        guard let code = account?.currency,
              let currency = Currency(rawValue: code) else { return "" }
        return currency.fullName
    }

    init(bankAccountService: BankAccountsService, transactionService: TransactionsService, categoriesService: CategoriesService) {
        self.bankAccountService = bankAccountService
        self.categoriesService = categoriesService
        self.transactionService = transactionService
    }

    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            account = try await bankAccountService.getAccount()

            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let startDate = calendar.date(byAdding: .day, value: -29, to: today)!
            let endDate = calendar.date(byAdding: .day, value: 1, to: today)!

            let categories = try await categoriesService.getAll()
            let transactions = try await transactionService.getTransactions(from: startDate, to: endDate)

            let grouped = Dictionary(grouping: transactions) { transaction -> Date in
                calendar.startOfDay(for: transaction.transactionDate)
            }

            var results: [BalanceBar] = []

            for offset in (0..<30).reversed() {
                let day = calendar.date(byAdding: .day, value: -offset, to: today)!
                let dayTransactions = grouped[day] ?? []

                var dailyTotal: Decimal = 0

                for transaction in dayTransactions {
                    //print("\(transaction.transactionDate) \(transaction.amount)")
                    if let category = categories.first(where: { $0.id == transaction.categoryId }) {
                        switch category.direction {
                        case .income:
                            dailyTotal += transaction.amount
                        case .outcome:
                            dailyTotal -= transaction.amount
                        }
                    }
                }

                results.append(BalanceBar(date: day, balance: dailyTotal))
            }

            await MainActor.run {
                self.balances = results
            }

        } catch is CancellationError {
            print("Вышел с экрана, задача отменилась")
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
    }


    func refresh() async {
        await load()
    }

    func updateAccount() async {
        guard let amount = Decimal(string: formattedBalanceText) else { return }

        if amount == account?.balance && localCurrency.rawValue == account?.currency {return}
        
        isLoading = true
        error = nil
        defer { isLoading = false }
        print(localCurrency.rawValue)
        do {
            try await bankAccountService.updateAccount(amount: amount, newCurrencyCode: localCurrency.rawValue)
            account = try await bankAccountService.getAccount()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func formatBalanceText() {
            let filtered = localBalanceText
                .filter { "0123456789,.".contains($0) }
                .replacingOccurrences(of: ",", with: ".")
            let components = filtered.components(separatedBy: ".")
            if components.count > 1 {
                formattedBalanceText = components[0] + "." + components.dropFirst().joined()
            } else {
                formattedBalanceText = filtered
            }
            localBalanceText = formattedBalanceText
        }
}
