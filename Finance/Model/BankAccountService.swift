//
//  BankAccountService.swift
//  Finance
//
//  Created by Stepan Polyakov on 14.07.2025.
//

import Foundation
final class BankAccountsService {
    private let networkClient: NetworkClient
    
    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
    
    func getAccount() async throws -> BankAccount {
        do {
            let accounts: [APIAccount] = try await networkClient.request(
                method: "GET",
                path: "accounts",
                responseType: [APIAccount].self
            )
                
            guard let account = accounts.first else {
                throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: ""])
            }
                
            return BankAccount(
                id: account.id,
                userID: account.userId,
                name: account.name,
                balance: Decimal(string: account.balance) ?? 0,
                currency: account.currency,
                createdAt: account.createdAt,
                updatedAt: account.updatedAt
            )
        } catch {
            throw NetworkError.noInternet
        }
    }
    
    func updateAccount(amount: Decimal, newCurrencyCode: String) async throws -> BankAccount {
        let account = try await getAccount()
        
        let request = UpdateAccountRequest(
            name: account.name,
            balance: "\(amount)",
            currency: newCurrencyCode
        )
        
        let updatedAccount: APIAccount = try await networkClient.request(
            method: "PUT",
            path: "accounts/\(account.id)",
            body: request,
            responseType: APIAccount.self
        )
        
        return BankAccount(
            id: updatedAccount.id,
            userID: updatedAccount.userId,
            name: updatedAccount.name,
            balance: Decimal(string: updatedAccount.balance) ?? 0,
            currency: updatedAccount.currency,
            createdAt: updatedAccount.createdAt,
            updatedAt: updatedAccount.updatedAt
        )
    }
    
    func getCurrentAccountId() async throws -> Int {
        let account = try await getAccount()
        return account.id
    }
}


private struct APIAccount: Decodable {
    let id: Int
    let userId: Int
    let name: String
    let balance: String
    let currency: String
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "userId"
        case name
        case balance
        case currency
        case createdAt
        case updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        userId = try container.decode(Int.self, forKey: .userId)
        name = try container.decode(String.self, forKey: .name)
        balance = try container.decode(String.self, forKey: .balance)
        currency = try container.decode(String.self, forKey: .currency)
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
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

private struct UpdateAccountRequest: Encodable {
    let name: String
    let balance: String
    let currency: String
}
