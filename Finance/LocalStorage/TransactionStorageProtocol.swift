//
//  TransactionStorageProtocol.swift
//  Finance
//
//  Created by Stepan Polyakov on 16.07.2025.
//

import Foundation

protocol TransactionsStorageProtocol {
    func getAll() async throws -> [Transaction]
    func getTransactions(from: Date?, to: Date?) async throws -> [Transaction]
    func create(transaction: Transaction) async throws
    func update(transaction: Transaction) async throws
    func delete(id: Int) async throws
}
