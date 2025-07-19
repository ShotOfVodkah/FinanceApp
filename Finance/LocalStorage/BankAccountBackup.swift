//
//  BankAccountBackup.swift
//  Finance
//
//  Created by Stepan Polyakov on 17.07.2025.
//
import Foundation
import SwiftData

final class AccountBackupStorage {
    private let context: ModelContext
    
    init(container: ModelContainer) {
        self.context = ModelContext(container)
    }
    
    func allBackups() throws -> [BackupAccount] {
        try context.fetch(FetchDescriptor<BackupAccount>(
            sortBy: [SortDescriptor(\.createdAt)]
        ))
    }
    
    func addChangeCurrency(newCurrency: String) throws {
        let backup = BackupAccount(action: .changeCurrency, stringValue: newCurrency)
        context.insert(backup)
        try context.save()
    }
    
    func addBalanceChange(amount: Decimal) throws {
        let backup = BackupAccount(action: .changeBalance, decimalValue: amount)
        context.insert(backup)
        try context.save()
    }
    
    func addTransactionChange(amountDelta: Decimal) throws {
        let backup = BackupAccount(action: .changeTransaction, decimalValue: amountDelta)
        context.insert(backup)
        try context.save()
    }
    
    func remove(id: UUID) throws {
        let descriptor = FetchDescriptor<BackupAccount>(predicate: #Predicate { $0.id == id })
        if let backup = try context.fetch(descriptor).first {
            context.delete(backup)
            try context.save()
        }
    }
}
