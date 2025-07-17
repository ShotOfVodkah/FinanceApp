//
//  TransactionBackupModel.swift
//  Finance
//
//  Created by Stepan Polyakov on 16.07.2025.
//

import Foundation
import SwiftData

enum ActionTransaction: String, Codable {
    case create
    case update
    case delete
}

enum ActionAccount: String, Codable {
    case changeCurrency
    case changeBalance
    case changeTransaction
}

@Model
final class BackupTransaction {
    @Attribute(.unique) var id: UUID
    var action: String
    var data: Data

    init(action: ActionTransaction, transaction: Transaction) {
        self.id = UUID()
        self.action = action.rawValue
        self.data = try! JSONEncoder().encode(transaction)
    }

    func toTransaction() -> Transaction? {
        try? JSONDecoder().decode(Transaction.self, from: data)
    }

    var actionType: ActionTransaction? {
        ActionTransaction(rawValue: action)
    }
}

@Model
final class BackupAccount {
    @Attribute(.unique) var id: UUID
    var action: ActionAccount
    var decimalValue: Decimal?
    var stringValue: String?
    var createdAt: Date
    
    init(action: ActionAccount, decimalValue: Decimal? = nil, stringValue: String? = nil) {
        self.id = UUID()
        self.action = action
        self.decimalValue = decimalValue
        self.stringValue = stringValue
        self.createdAt = Date()
        
        switch action {
        case .changeCurrency:
            assert(stringValue != nil, "Для changeCurrency требуется stringValue")
        case .changeBalance, .changeTransaction:
            assert(decimalValue != nil, "Для \(action) требуется decimalValue")
        }
    }
}
