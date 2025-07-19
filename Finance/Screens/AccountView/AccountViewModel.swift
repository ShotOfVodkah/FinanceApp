//
//  BankAccountViewModel.swift
//  Finance
//
//  Created by Stepan Polyakov on 23.06.2025.
//

import Foundation

@MainActor
final class AccountViewModel: ObservableObject {
    private let bankAccountService: BankAccountsService

    @Published var account: BankAccount?
    @Published var isLoading = false
    @Published var error: String?

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

    init(bankAccountService: BankAccountsService) {
        self.bankAccountService = bankAccountService
    }

    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            account = try await bankAccountService.getAccount()
        } catch is CancellationError {
            print("Вышел с экрана, задача отменилась")
        } catch {
            self.error = error.localizedDescription
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
