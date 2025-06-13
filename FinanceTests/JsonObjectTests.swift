//
//  JsonObjectTests.swift
//  FinanceApp
//
//  Created by Stepan Polyakov on 10.06.2025.
//

import XCTest
@testable import Finance

final class JsonObjectTests: XCTestCase {
    func testJsonObject() throws {
        let account = BankAccount(id: 1, userID: 42, name: "Main", balance: 1234.56, currency: "EUR", createdAt: Date(), updatedAt: Date())
        let category = Category(id: 2, name: "Salary", emoji: "💰", direction: .income)
        let transaction = Transaction(id: 555, account: account, category: category, amount: 999.99, transactionDate: Date(), comment: "Paycheck", createdAt: Date(), updatedAt: Date())

        let jsonObject = transaction.jsonObject
        XCTAssertTrue(jsonObject is [String: Any])
        guard let parsed = Transaction.parse(jsonObject: jsonObject) else {
            return
        }
        XCTAssertEqual(parsed.id, transaction.id)
        XCTAssertEqual(parsed.amount, transaction.amount)
        XCTAssertEqual(parsed.comment, transaction.comment)
    }
}
