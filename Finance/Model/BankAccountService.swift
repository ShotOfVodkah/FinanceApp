//
//  BankAccountService.swift
//  Finance
//
//  Created by Stepan Polyakov on 14.07.2025.
//

import Foundation
final class BankAccountsService {
    private let networkClient: NetworkClient
    let localStorage: AccountStorageProtocol
    let backupStorage: AccountBackupStorage
    
    init(networkClient: NetworkClient, localStorage: AccountStorageProtocol, backupStorage: AccountBackupStorage) {
        self.networkClient = networkClient
        self.localStorage = localStorage
        self.backupStorage = backupStorage
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
                
            let bankAccount = BankAccount(
                id: account.id,
                userID: account.userId,
                name: account.name,
                balance: Decimal(string: account.balance) ?? 0,
                currency: account.currency,
                createdAt: account.createdAt,
                updatedAt: account.updatedAt
            )
            try await localStorage.saveAccount(account: bankAccount)
            return bankAccount
        } catch let error as NetworkError {
            if case .noInternet = error  {
                var account = try await localStorage.getAccount()
                let backups = try backupStorage.allBackups()
                for backup in backups {
                    switch backup.action {
                    case .changeCurrency:
                        if let newCurrency = backup.stringValue {
                            account.currency = newCurrency
                        }
                    
                    case .changeBalance:
                        if let amount = backup.decimalValue {
                            account.balance += amount
                        }
                    
                    case .changeTransaction:
                        if let delta = backup.decimalValue {
                            account.balance += delta
                        }
                    }
                }
                return account
            } else {
                throw error
            }
        }
    }
    
    func updateAccount(amount: Decimal, newCurrencyCode: String) async throws -> BankAccount {
        do {
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
            
            let bankAccount = BankAccount(
                id: updatedAccount.id,
                userID: updatedAccount.userId,
                name: updatedAccount.name,
                balance: Decimal(string: updatedAccount.balance) ?? 0,
                currency: updatedAccount.currency,
                createdAt: updatedAccount.createdAt,
                updatedAt: updatedAccount.updatedAt
            )
            try await localStorage.updateAccount(amount: bankAccount.balance, currencyCode: bankAccount.currency)
            return bankAccount
        } catch let error as NetworkError {
            if case .noInternet = error  {
                var account = try await localStorage.getAccount()
                let backups = try backupStorage.allBackups()
                for backup in backups {
                    switch backup.action {
                    case .changeCurrency:
                        if let newCurrency = backup.stringValue {
                            account.currency = newCurrency
                        }
                    
                    case .changeBalance:
                        if let amount = backup.decimalValue {
                            account.balance += amount
                        }
                    
                    case .changeTransaction:
                        if let delta = backup.decimalValue {
                            account.balance += delta
                        }
                    }
                }
                try backupStorage.addBalanceChange(amount: amount - account.balance)
                try backupStorage.addChangeCurrency(newCurrency: newCurrencyCode)
                account.balance = amount
                account.currency = newCurrencyCode
                return account
            } else {
                throw error
            }
        }
    }
    
    func getCurrentAccountId() async throws -> Int {
        do {
            let account = try await getAccount()
            return account.id
        } catch let error as NetworkError {
            if case .noInternet = error {
                return try await localStorage.getCurrentAccountId()
            } else {
                throw error
            }
        }
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
                debugDescription: "Date string does not match format."
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
