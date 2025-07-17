//
//  TransactionBackupModel.swift
//  Finance
//
//  Created by Stepan Polyakov on 16.07.2025.
//

import Foundation
import SwiftData

enum Action: String, Codable {
    case create
    case update
    case delete
}

@Model
final class BackupTransaction {
    @Attribute(.unique) var id: UUID
    var action: String
    var data: Data

    init(action: Action, transaction: Transaction) {
        self.id = UUID()
        self.action = action.rawValue
        self.data = try! JSONEncoder().encode(transaction)
    }

    func toTransaction() -> Transaction? {
        try? JSONDecoder().decode(Transaction.self, from: data)
    }

    var actionType: Action? {
        Action(rawValue: action)
    }
}
