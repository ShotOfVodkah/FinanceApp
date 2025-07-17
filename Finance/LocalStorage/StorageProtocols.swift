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

protocol CategoriesStorageProtocol {
    func getAllCategories() async throws -> [Category]
    func getCategories(by direction: Direction) async throws -> [Category]
    func saveCategories(_ categories: [Category]) async throws
}

protocol AccountStorageProtocol {
    func getAccount() async throws -> BankAccount
    func updateAccount(amount: Decimal, currencyCode: String) async throws
    func saveAccount(account: BankAccount) async throws
    func getCurrentAccountId() async throws -> Int
}
