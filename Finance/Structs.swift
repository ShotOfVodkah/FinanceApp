//
//  Structs.swift
//  FinanceApp
//
//  Created by Stepan Polyakov on 08.06.2025.
//

import Foundation

enum Direction: String, Codable {
    case income
    case outcome
}

enum Currency: String, CaseIterable {
    case rub = "RUB"
    case usd = "USD"
    case eur = "EUR"
    
    var symbol: String {
        switch self {
        case .rub: return "₽"
        case .usd: return "$"
        case .eur: return "€"
        }
    }
    
    var fullName: String {
        switch self {
        case .rub: return "Российский рубль ₽"
        case .usd: return "Американский доллар $"
        case .eur: return "Евро €"
        }
    }
}

struct Category: Identifiable, Codable {
    var id: Int
    var name: String
    var direction: Direction
    var emoji: Character
    
    enum keys: String, CodingKey {
        case id, name, emoji, isIncome
    }
    
    init (id: Int, name: String, emoji: Character, direction: Direction) {
        self.id = id
        self.direction = direction
        self.emoji = emoji
        self.name = name
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: keys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        let emojiStr = try container.decode(String.self, forKey: .emoji)
        emoji = emojiStr.first ?? "?"
        direction = try container.decode(Bool.self, forKey: .isIncome) ? .income : .outcome
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: keys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(String(emoji), forKey: .emoji)
        try container.encode(direction == .income, forKey: .isIncome)
    }
}

struct BankAccount: Identifiable, Codable {
    var id: Int
    var userId: Int?
    var name: String
    var balance: Decimal
    var currency: String
    var createdAt: Date?
    var updatedAt: Date?
    
    init(id: Int, userID: Int?, name: String, balance: Decimal, currency: String, createdAt: Date?, updatedAt: Date?) {
        self.id = id
        self.userId = userID
        self.name = name
        self.balance = balance
        self.currency = currency
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    enum keys: String, CodingKey {
        case id, userId, name, balance, currency, createdAt, updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: keys.self)
        id = try container.decode(Int.self, forKey: .id)
        userId = try? container.decode(Int.self, forKey: .userId)
        name = try container.decode(String.self, forKey: .name)
        let tmp = try container.decode(String.self, forKey: .balance)
        balance = Decimal(string: tmp) ?? 0
        currency = try container.decode(String.self, forKey: .currency)
        createdAt = try? container.decode(Date.self, forKey: .createdAt)
        updatedAt = try? container.decode(Date.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: keys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode("\(balance)", forKey: .balance)
        try container.encode(currency, forKey: .currency)
        
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }
}

struct Transaction: Identifiable,Codable {
    var id: Int
    var accountId: Int
    var categoryId: Int
    var amount: Decimal
    var transactionDate: Date
    var comment: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(id: Int, account: Int, category: Int, amount: Decimal, transactionDate: Date, comment: String, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.accountId = account
        self.amount = amount
        self.categoryId = category
        self.comment = comment
        self.createdAt = createdAt
        self.transactionDate = transactionDate
        self.updatedAt = updatedAt
    }
    
    enum keys: String, CodingKey {
        case id, accountId, categoryId,amount, transactionDate, comment, createdAt, updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: keys.self)
        id = try container.decode(Int.self, forKey: .id)
        accountId = try container.decode(Int.self, forKey: .accountId)
        categoryId = try container.decode(Int.self, forKey: .categoryId)
        let tmp = try container.decode(String.self, forKey: .amount)
        amount = Decimal(string: tmp) ?? 0
        transactionDate = try container.decode(Date.self, forKey: .transactionDate)
        comment = try? container.decode(String.self, forKey: .comment)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: keys.self)
        try container.encode(id, forKey: .id)
        try container.encode(accountId, forKey: .accountId)
        try container.encode(categoryId, forKey: .categoryId)
        try container.encode("\(amount)", forKey: .amount)
        try container.encode(transactionDate, forKey: .transactionDate)
        try container.encodeIfPresent(comment, forKey: .comment)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

extension Transaction {
    static func parse(jsonObject: Any) -> Transaction? {
        guard let data = try? JSONSerialization.data(withJSONObject: jsonObject, options: []) else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(Transaction.self, from: data)
    }

    var jsonObject: Any {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(self),
              let json = try? JSONSerialization.jsonObject(with: data, options: []) else { return [:] }
        return json
    }
}
