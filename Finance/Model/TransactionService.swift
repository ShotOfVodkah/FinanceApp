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
    private let localStorage: TransactionsStorageProtocol
    private let backupStorage: TransactionBackupStorage
    private let idGenerator = TemporaryIDGenerator()
    
    private func generateTemporaryId() -> Int {
        return idGenerator.generate()
    }
    
    init(networkClient: NetworkClient, bankAccountsService: BankAccountsService, localStorage: TransactionsStorageProtocol, backupStorage: TransactionBackupStorage) {
        self.networkClient = networkClient
        self.bankAccountsService = bankAccountsService
        self.localStorage = localStorage
        self.backupStorage = backupStorage
    }
    
    private func getCurrentAccountId() async throws -> Int {
        return try await bankAccountsService.getCurrentAccountId()
    }
    
    func getTransactions(from: Date? = nil, to: Date? = nil) async throws -> [Transaction] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")!
            
        var queryItems = [URLQueryItem]()
            
        if let from = from, let to = to {
            var utcCalendar = Calendar(identifier: .gregorian)
            utcCalendar.timeZone = TimeZone(identifier: "UTC")!
            let utcFrom = utcCalendar.startOfDay(for: from)
            let utcTo = utcCalendar.startOfDay(for: to.addingTimeInterval(86400))
            queryItems.append(URLQueryItem(name: "startDate", value: dateFormatter.string(from: utcFrom)))
            queryItems.append(URLQueryItem(name: "endDate", value: dateFormatter.string(from: utcTo)))
        }
            
        do {
            let accountId = try await getCurrentAccountId()
            let response: [APITransactionResponse] = try await networkClient.request(
                method: "GET",
                path: "transactions/account/\(accountId)/period",
                queryItems: queryItems.isEmpty ? nil : queryItems,
                responseType: [APITransactionResponse].self
            )
            try await syncBackups()
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
        } catch let error as NetworkError {
            if case .noInternet = error  {
                return try await mergedTransactions(from: from, to: to)
            } else {
                throw error
            }
        }
    }
    
    private func mergedTransactions(from: Date?, to: Date?) async throws -> [Transaction] {
        let localTransactions = try await localStorage.getTransactions(from: from, to: to)
        
        let backups = try backupStorage.allBackups()
        var transactionsDict = Dictionary(uniqueKeysWithValues: localTransactions.map { ($0.id, $0) })
        for backup in backups {
            guard let action = backup.actionType,
                  let transaction = backup.toTransaction() else { continue }
            
            switch action {
            case .create:
                transactionsDict[transaction.id] = transaction
            case .update:
                if transactionsDict[transaction.id] != nil {
                    transactionsDict[transaction.id] = transaction
                }
            case .delete:
                transactionsDict.removeValue(forKey: transaction.id)
            }
        }
        let mergedTransactions = Array(transactionsDict.values)
        if let from = from, let to = to {
            return mergedTransactions.filter {
                $0.transactionDate >= from && $0.transactionDate <= to
            }
        }
        return mergedTransactions
    }
    
    private func syncBackups() async throws{
        let backupsStorage = try backupStorage.allBackups()
        let backupsAccount = try bankAccountsService.backupStorage.allBackups()
        for backup in backupsStorage {
                do {
                    switch backup.actionType {
                    case .create:
                        let backupTransaction = backup.toTransaction()!
                        let transaction = try await addTransaction(transaction: backupTransaction, dir: .income)
                        try backupStorage.remove(id: backup.id)
                        
                    case .update:
                        let backupTransaction = backup.toTransaction()!
                        let transaction = try await editTransaction(
                            id: backupTransaction.id,
                            categoryId: backupTransaction.categoryId,
                            accountId: backupTransaction.accountId,
                            amount: backupTransaction.amount,
                            transactionDate: backupTransaction.transactionDate,
                            comment: backupTransaction.comment, dir: .outcome, prev: backupTransaction.amount
                        )
                        try backupStorage.remove(id: backup.id)
                        
                    case .delete:
                        let backupTransaction = backup.toTransaction()!
                        try await deleteTransaction(id: backupTransaction.id, prev: backupTransaction.amount, dir: .income)
                        try backupStorage.remove(id: backup.id)
                    case nil:
                        continue
                    }
                } catch {
                    continue
                }
            }
        var account = try await bankAccountsService.getAccount()
        for backup in backupsAccount {
            switch backup.action {
            case .changeCurrency:
                if let newCurrency = backup.stringValue {
                    account.currency = newCurrency
                }
            
            case .changeBalance:
                if let amount = backup.decimalValue {
                    account.balance += amount
                }
            
            case .changeTransaction: continue
            }
        }
        try await bankAccountsService.updateAccount(amount: account.balance, newCurrencyCode: account.currency)
        print("бекапы загрузил")
    }
    
    func addTransaction(transaction: Transaction, dir: Direction) async throws -> Transaction {

        do {
            let request = CreateTransactionRequest(
                accountId: transaction.accountId,
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
                
            let transactionServer = Transaction(
                id: response.id,
                account: response.accountId,
                category: response.categoryId,
                amount: Decimal(string: response.amount) ?? 0,
                transactionDate: response.transactionDate,
                comment: response.comment ?? "",
                createdAt: response.createdAt,
                updatedAt: response.updatedAt
            )
            try await localStorage.create(transaction: transactionServer)
            return transactionServer
        } catch let error as NetworkError {
            if case .noInternet = error  {
                var localTransaction = transaction
                localTransaction.id = generateTemporaryId()
                try backupStorage.add(action: .create, transaction: localTransaction)
                try bankAccountsService.backupStorage.addTransactionChange(amountDelta: dir == .income ? localTransaction.amount : -localTransaction.amount)
                return localTransaction
            } else {
                throw error
            }
        }
    }
    
    func editTransaction(id: Int, categoryId: Int, accountId: Int, amount: Decimal, transactionDate: Date, comment: String?, dir: Direction, prev: Decimal) async throws -> Transaction {
        do {
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
            
            let transactionServer = Transaction(
                id: response.id,
                account: response.account.id,
                category: response.category.id,
                amount: Decimal(string: response.amount) ?? 0,
                transactionDate: response.parsedTransactionDate,
                comment: response.comment ?? "",
                createdAt: response.parsedCreatedAt,
                updatedAt: response.parsedUpdatedAt
            )
            try await localStorage.update(transaction: transactionServer)
            return transactionServer
        } catch let error as NetworkError {
            if case .noInternet = error  {
                let localTransaction = Transaction(
                        id: id,
                        account: try await getCurrentAccountId(),
                        category: categoryId,
                        amount: amount,
                        transactionDate: transactionDate,
                        comment: comment ?? "",
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                try backupStorage.add(action: .update, transaction: localTransaction)
                try bankAccountsService.backupStorage.addTransactionChange(amountDelta: dir == .income ? (localTransaction.amount - prev) : -(localTransaction.amount - prev))
                return localTransaction
            } else {
                throw error
            }
        }
    }
    
    func deleteTransaction(id: Int, prev: Decimal, dir: Direction) async throws {
        do {
            try await networkClient.request(
                method: "DELETE",
                path: "transactions/\(id)",
                responseType: EmptyResponse.self
            )
            try await localStorage.delete(id: id)
        } catch let error as NetworkError {
            if case .noInternet = error  {
                try backupStorage.add(action: .delete, transaction: Transaction(id: id, account: 0, category: 0, amount: 0, transactionDate: Date(), comment: "", createdAt: Date(), updatedAt: Date()))
                try bankAccountsService.backupStorage.addTransactionChange(amountDelta:  dir == .income ? -prev : prev)
            } else {
                throw error
            }
        }
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
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let dateString = formatter.string(from: transactionDate)
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
