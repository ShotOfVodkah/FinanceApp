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
