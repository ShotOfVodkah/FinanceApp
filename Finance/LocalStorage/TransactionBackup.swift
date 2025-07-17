//
//  TransactionBackup.swift
//  Finance
//
//  Created by Stepan Polyakov on 16.07.2025.
//

import SwiftData
import Foundation

final class TransactionBackupStorage {
    private let context: ModelContext

    init(container: ModelContainer) {
        self.context = ModelContext(container)
    }

    func allBackups() throws -> [BackupTransaction] {
        try context.fetch(FetchDescriptor<BackupTransaction>())
    }

    func add(action: ActionTransaction, transaction: Transaction) throws {
        let backup = BackupTransaction(action: action, transaction: transaction)
        context.insert(backup)
        try context.save()
        print("операция добавлена в бекап \(transaction.id)")
    }

    func remove(id: UUID) throws {
        let descriptor = FetchDescriptor<BackupTransaction>(predicate: #Predicate { $0.id == id })
        if let record = try context.fetch(descriptor).first {
            context.delete(record)
            try context.save()
        }
        print("убрано из бекапа")
    }
}
