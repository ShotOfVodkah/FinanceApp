//
//  BankAccountViewModel.swift
//  Finance
//
//  Created by Stepan Polyakov on 23.06.2025.
//

import Foundation

enum Currency: String, CaseIterable {
    case rub = "RUB"
    case usd = "USD"
    case eur = "EUR"
    
    var symbol: String {
        switch self {
        case .rub: return "₽"
        case .usd: return "$"
        case .eur: return "€"
        }
    }
    
    var fullName: String {
        switch self {
        case .rub: return "Российский рубль ₽"
        case .usd: return "Американский доллар $"
        case .eur: return "Евро €"
        }
    }
}


@MainActor
final class AccountViewModel: ObservableObject {
    private let bankAccountService : BankAccountsService
    
    @Published var account: BankAccount?
    
    var currency: String {
        guard let code = account?.currency,
              let currency = Currency(rawValue: code) else { return "" }
        return currency.symbol
    }
    var currencyString: String {
        guard let code = account?.currency,
              let currency = Currency(rawValue: code) else { return "" }
        return currency.fullName
    }


    
    init(bankAccountService: BankAccountsService) {
        self.bankAccountService = bankAccountService
    }
    
    
    func load() async {
        self.account = await bankAccountService.getAccount()
    }
    
    func refresh() async {
        await load()
    }
    
    func updateBalance(input: String) async {
        let filtered = input
            .filter { "0123456789,.".contains($0) }
            .replacingOccurrences(of: ",", with: ".")

        guard let amount = Decimal(string: filtered) else {
            return
        }
        await bankAccountService.newBalance(amount: amount)
        self.account = await bankAccountService.getAccount()
    }

        
    func updateCurrency(newCurrency: String) async {
        if newCurrency == account?.currency {
            return
        }
        await bankAccountService.changeCurrency(newCurrencyCode: newCurrency)
        self.account = await bankAccountService.getAccount()
    }
}
