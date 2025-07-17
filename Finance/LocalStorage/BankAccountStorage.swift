//
//  BankAccountStorage.swift
//  Finance
//
//  Created by Stepan Polyakov on 17.07.2025.
//

import SwiftData
import Foundation
final class SwiftDataAccountStorage: AccountStorageProtocol {
    private let modelContext: ModelContext
    
    init(container: ModelContainer) {
        self.modelContext = ModelContext(container)
    }
    
    func getAccount() async throws -> BankAccount {
        let descriptor = FetchDescriptor<BankAccountStorage>()
        let accounts = try modelContext.fetch(descriptor)
        
        guard let account = accounts.first else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No account found in local storage"])
        }
        
        return account.toBankAccount()
    }
    
    func updateAccount(amount: Decimal, currencyCode: String) async throws {
        let descriptor = FetchDescriptor<BankAccountStorage>()
        guard let account = try modelContext.fetch(descriptor).first else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No account to update"])
        }
        
        account.balance = "\(amount)"
        account.currency = currencyCode
        account.updatedAt = Date()
        
        try modelContext.save()
    }
    
    func saveAccount(account: BankAccount) async throws {
        let descriptor = FetchDescriptor<BankAccountStorage>(predicate: #Predicate { $0.id == account.id })
        
        if let existing = try modelContext.fetch(descriptor).first {
            existing.userId = account.userId
            existing.name = account.name
            existing.balance = "\(account.balance)"
            existing.currency = account.currency
            existing.createdAt = account.createdAt
            existing.updatedAt = account.updatedAt
        } else {
            modelContext.insert(BankAccountStorage(from: account))
            print("создал аккаунт")
        }
        try modelContext.save()
    }
    
    func getCurrentAccountId() async throws -> Int {
        let account = try await getAccount()
        return account.id
    }
}
