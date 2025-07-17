//
//  TransactionStorage.swift
//  Finance
//
//  Created by Stepan Polyakov on 16.07.2025.
//

import SwiftData
import Foundation

final class SwiftDataTransactionStorage: TransactionsStorageProtocol {
    
    private let modelContext: ModelContext

    init(container: ModelContainer) {
        self.modelContext = ModelContext(container)
    }

    func getAll() async throws -> [Transaction] {
        let descriptor = FetchDescriptor<TransactionStorage>()
        return try modelContext.fetch(descriptor).map { $0.toTransaction() }
    }

    func getTransactions(from: Date?, to: Date?) async throws -> [Transaction] {
        var predicate: Predicate<TransactionStorage> = #Predicate { _ in true }

        if let from = from, let to = to {
            predicate = #Predicate {
                $0.transactionDate >= from && $0.transactionDate <= to
            }
        }

        let descriptor = FetchDescriptor<TransactionStorage>(predicate: predicate)
        return try modelContext.fetch(descriptor).map { $0.toTransaction() }
    }

    func create(transaction: Transaction) async throws {
        modelContext.insert(TransactionStorage(from: transaction))
        try modelContext.save()
        print("добавлено в локальный storage \(transaction.id)")
    }

    func update(transaction: Transaction) async throws {
        let fetch = FetchDescriptor<TransactionStorage>(predicate: #Predicate { $0.id == transaction.id })
        if let existing = try modelContext.fetch(fetch).first {
            existing.account = transaction.accountId
            existing.category = transaction.categoryId
            existing.amount = transaction.amount
            existing.transactionDate = transaction.transactionDate
            existing.comment = transaction.comment
            existing.createdAt = transaction.createdAt
            existing.updatedAt = transaction.updatedAt
            try modelContext.save()
        }
    }

    func delete(id: Int) async throws {
        let fetch = FetchDescriptor<TransactionStorage>(predicate: #Predicate { $0.id == id })
        if let transaction = try modelContext.fetch(fetch).first {
            modelContext.delete(transaction)
            try modelContext.save()
        }
    }
}
