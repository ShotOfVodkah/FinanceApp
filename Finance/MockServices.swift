//
//  MockServices.swift
//  FinanceApp
//
//  Created by Stepan Polyakov on 09.06.2025.
//

import Foundation

//final class CategoriesService {
//    private let categories: [Category] = [
//        Category(id: 1, name: "Shopping", emoji: "🛒", direction: .outcome),
//        Category(id: 2, name: "Salary", emoji: "💵", direction: .income),
//        Category(id: 3, name: "Medical", emoji: "🚑", direction: .outcome),
//        Category(id: 4, name: "Twirling and swirling", emoji: "👠", direction: .income)
//    ]
//    
//    func getAll() async -> [Category] {
//        return categories
//    }
//    
//    func getSpecific(dir: Direction) async -> [Category] {
//        return categories.filter {$0.direction == dir}
//    }
//}


//final class  BankAccountsService {
//    private var account: BankAccount = BankAccount(id: 1, userID: 1, name: "My account", balance: 100000.00, currency: "RUB", createdAt: Date(), updatedAt: Date())
//    
//    func getAccount() async -> BankAccount {
//        return account
//    }
//    
//    func changeBalance(amount: Decimal, add: Bool) async {
//        if add {
//            account.balance += amount
//            account.updatedAt = Date()
//        } else {
//            account.balance -= amount
//            account.updatedAt = Date()
//        }
//    }
//    
//    func changeCurrency(newCurrencyCode: String) async {
//        guard let newCurrency = Currency(rawValue: newCurrencyCode),
//              let currentCurrency = Currency(rawValue: account.currency),
//              newCurrency != currentCurrency
//        else {
//            return
//        }
//
//        self.account.currency = newCurrency.rawValue
//        self.account.updatedAt = Date()
//    }
//
//    
//    func newBalance(amount: Decimal) async {
//        account.balance = amount
//        account.updatedAt = Date()
//    }
//}

//final class  TransactionsService {
//    private var transactions: [Transaction] = [
//        Transaction(id: 1, account: 1, category: 1, amount: 200.00, transactionDate: Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 1))!, comment: "a", createdAt: Date(), updatedAt: Date()),
//        Transaction(id: 2, account: 1, category: 2, amount: 400.00, transactionDate: Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 1))!, comment: "b", createdAt: Date(), updatedAt: Date()),
//        Transaction(id: 3, account: 1, category: 3, amount: 400.00, transactionDate: Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 1))!, comment: "c", createdAt: Date(), updatedAt: Date()),
//        Transaction(id: 4, account: 1, category: 4, amount: 300.00, transactionDate: Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 2))!, comment: "d", createdAt: Date(), updatedAt: Date()),
//        Transaction(id: 5, account: 1, category: 4, amount: 500.00, transactionDate: Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 3))!, comment: "d", createdAt: Date(), updatedAt: Date()),
//        Transaction(id: 6, account: 1, category: 3, amount: 400.00, transactionDate: Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!, comment: "c", createdAt: Date(), updatedAt: Date()),
//        Transaction(id: 7, account: 1, category: 4, amount: 300.00, transactionDate: Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!, comment: "d", createdAt: Date(), updatedAt: Date())
//    ]
//    
//    func getTransactions(from: Date, to: Date) async -> [Transaction] {
//        return transactions.filter { $0.transactionDate >= from && $0.transactionDate <= to}
//    }
//    
//    func addTransaction(transaction: Transaction) async {
//        transactions.append(transaction)
//    }
//    
//    func editTransaction(id: Int, category: Int? = nil, amount: Decimal? = nil, transactionDate: Date? = nil, comment: String? = nil) async {
//        guard let idx = transactions.firstIndex(where: { $0.id == id }) else {
//            return
//        }
//        if let category {transactions[idx].categoryId = category}
//        if let amount {transactions[idx].amount = amount}
//        if let transactionDate {transactions[idx].transactionDate = transactionDate}
//        if let comment {transactions[idx].comment = comment}
//    }
//    
//    func deleteTransaction(id: Int) async {
//        transactions.removeAll {$0.id == id}
//    }
//    
//    func getId() -> Int {
//        return transactions.count + 1
//    }
//}
