//
//  TransactionService.swift
//  Finance
//
//  Created by Stepan Polyakov on 14.07.2025.
//

import Foundation

final class TransactionsService {
    private let networkClient: NetworkClient
    private let bankAccountsService: BankAccountsService
    
    init(networkClient: NetworkClient, bankAccountsService: BankAccountsService) {
        self.networkClient = networkClient
        self.bankAccountsService = bankAccountsService
    }
    
    private func getCurrentAccountId() async throws -> Int {
        return try await bankAccountsService.getCurrentAccountId()
    }
    
    func getTransactions(from: Date? = nil, to: Date? = nil) async throws -> [Transaction] {
        let accountId = try await getCurrentAccountId()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
            
        var queryItems = [URLQueryItem]()
        
        if let from = from {
            queryItems.append(URLQueryItem(name: "startDate", value: dateFormatter.string(from: from)))
        }
        if let to = to {
            queryItems.append(URLQueryItem(name: "endDate", value: dateFormatter.string(from: to)))
        }
            
        do {
            let response: [APITransactionResponse] = try await networkClient.request(
                method: "GET",
                path: "transactions/account/\(accountId)/period",
                queryItems: queryItems.isEmpty ? nil : queryItems,
                responseType: [APITransactionResponse].self
            )
                
            return response.map {
                Transaction(
                    id: $0.id,
                    account: $0.account.id,
                    category: $0.category.id,
                    amount: Decimal(string: $0.amount) ?? 0,
                    transactionDate: $0.parsedTransactionDate,
                    comment: $0.comment ?? "",
                    createdAt: $0.parsedCreatedAt,
                    updatedAt: $0.parsedUpdatedAt
                )
            }
        } catch {
            print("Decoding error details: \(error)")
            throw error
        }
    }
    
    func addTransaction(transaction: Transaction) async throws -> Transaction {
        let accountId = try await getCurrentAccountId()
        let request = CreateTransactionRequest(
            accountId: accountId,
            categoryId: transaction.categoryId,
            amount: "\(transaction.amount)",
            transactionDate: transaction.transactionDate,
            comment: transaction.comment ?? ""
        )
            
        let response: TransactionResponse = try await networkClient.request(
            method: "POST",
            path: "transactions",
            body: request,
            responseType: TransactionResponse.self
        )
            
        return Transaction(
            id: response.id,
            account: response.accountId,
            category: response.categoryId,
            amount: Decimal(string: response.amount) ?? 0,
            transactionDate: response.transactionDate,
            comment: response.comment ?? "",
            createdAt: response.createdAt,
            updatedAt: response.updatedAt
        )
    }
    
    func editTransaction(id: Int, categoryId: Int, amount: Decimal, transactionDate: Date, comment: String?) async throws -> Transaction {
        let accountId = try await getCurrentAccountId()
        let request = UpdateTransactionRequest(
            accountId: accountId,
            categoryId: categoryId,
            amount: "\(amount)",
            transactionDate: transactionDate,
            comment: comment ?? ""
        )
        
        let response: APITransactionResponse = try await networkClient.request(
            method: "PUT",
            path: "transactions/\(id)",
            body: request,
            responseType: APITransactionResponse.self
        )
        
        return Transaction(
            id: response.id,
            account: response.account.id,
            category: response.category.id,
            amount: Decimal(string: response.amount) ?? 0,
            transactionDate: response.parsedTransactionDate,
            comment: response.comment ?? "",
            createdAt: response.parsedCreatedAt,
            updatedAt: response.parsedUpdatedAt
        )
    }
    
    func deleteTransaction(id: Int) async throws {
        try await networkClient.request(
            method: "DELETE",
            path: "transactions/\(id)",
            responseType: EmptyResponse.self
        )
    }
}

private struct APITransactionResponse: Decodable {
    let id: Int
    let account: APIAccount
    let category: APICategory
    let amount: String
    let transactionDate: String
    let comment: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case account
        case category
        case amount
        case transactionDate
        case comment
        case createdAt
        case updatedAt
    }
    
    var parsedTransactionDate: Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: transactionDate) ?? Date()
    }
    var parsedCreatedAt: Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: createdAt) ?? Date()
    }
    var parsedUpdatedAt: Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: updatedAt) ?? Date()
    }
}


private struct APIAccount: Decodable {
    let id: Int
    let name: String
    let balance: String
    let currency: String
}

private struct TransactionResponse: Decodable {
    let id: Int
    let accountId: Int
    let categoryId: Int
    let amount: String
    let transactionDate: Date
    let comment: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case accountId
        case categoryId
        case amount
        case transactionDate
        case comment
        case createdAt
        case updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        accountId = try container.decode(Int.self, forKey: .accountId)
        categoryId = try container.decode(Int.self, forKey: .categoryId)
        amount = try container.decode(String.self, forKey: .amount)
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let dateString = try container.decode(String.self, forKey: .transactionDate)
        guard let date = dateFormatter.date(from: dateString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .transactionDate,
                in: container,
                debugDescription: "Date string does not match format expected by formatter."
            )
        }
        transactionDate = date
        
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
        
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        let updatedAtString = try container.decode(String.self, forKey: .updatedAt)
        
        guard let createdAt = dateFormatter.date(from: createdAtString),
              let updatedAt = dateFormatter.date(from: updatedAtString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .createdAt,
                in: container,
                debugDescription: "Date string does not match format expected by formatter."
            )
        }
        
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

private struct CreateTransactionRequest: Encodable {
    let accountId: Int
    let categoryId: Int
    let amount: String
    let transactionDate: Date
    let comment: String
    
    enum CodingKeys: String, CodingKey {
        case accountId
        case categoryId
        case amount
        case transactionDate
        case comment
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accountId, forKey: .accountId)
        try container.encode(categoryId, forKey: .categoryId)
        try container.encode(amount, forKey: .amount)
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dateString = dateFormatter.string(from: transactionDate)
        try container.encode(dateString, forKey: .transactionDate)
        
        try container.encode(comment, forKey: .comment)
    }
}

private struct UpdateTransactionRequest: Encodable {
    let accountId: Int
    let categoryId: Int
    let amount: String
    let transactionDate: Date
    let comment: String
}

struct EmptyResponse: Decodable {}
