//
//  SwiftDataModels.swift
//  Finance
//
//  Created by Stepan Polyakov on 16.07.2025.
//

import Foundation
import SwiftData

@Model
final class TransactionStorage {
    @Attribute(.unique) var id: Int
    var account: Int
    var category: Int
    var amount: Decimal
    var transactionDate: Date
    var comment: String?
    var createdAt: Date
    var updatedAt: Date

    init(from transaction: Transaction) {
        self.id = transaction.id
        self.account = transaction.accountId
        self.category = transaction.categoryId
        self.amount = transaction.amount
        self.transactionDate = transaction.transactionDate
        self.comment = transaction.comment
        self.createdAt = transaction.createdAt
        self.updatedAt = transaction.updatedAt
    }

    func toTransaction() -> Transaction {
        Transaction(
            id: id,
            account: account,
            category: category,
            amount: amount,
            transactionDate: transactionDate,
            comment: comment ?? "",
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

@Model
final class CategoryStorage {
    @Attribute(.unique) var id: Int
    var name: String
    var emoji: String
    var isIncome: Bool
    
    init(from category: Category) {
        self.id = category.id
        self.name = category.name
        self.emoji = String(category.emoji)
        self.isIncome = category.direction == .income
    }
    
    func toCategory() -> Category {
        Category(
            id: id,
            name: name,
            emoji: emoji.first ?? "?",
            direction: isIncome ? .income : .outcome
        )
    }
}

@Model
final class BankAccountStorage {
    @Attribute(.unique) var id: Int
    var userId: Int?
    var name: String
    var balance: String
    var currency: String
    var createdAt: Date?
    var updatedAt: Date?
    
    init(from account: BankAccount) {
        self.id = account.id
        self.userId = account.userId
        self.name = account.name
        self.balance = "\(account.balance)"
        self.currency = account.currency
        self.createdAt = account.createdAt
        self.updatedAt = account.updatedAt
    }
    
    func toBankAccount() -> BankAccount {
        BankAccount(
            id: id,
            userID: userId,
            name: name,
            balance: Decimal(string: balance) ?? 0,
            currency: currency,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
