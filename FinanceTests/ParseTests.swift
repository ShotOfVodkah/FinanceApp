//
//  ParseTests.swift
//  FinanceApp
//
//  Created by Stepan Polyakov on 10.06.2025.
//

import XCTest
@testable import Finance

final class ParseTests: XCTestCase {
    func parseValid() throws {
        let account = BankAccount(id: 1, userID: 42, name: "Main", balance: 1000, currency: "USD", createdAt: Date(), updatedAt: Date())
        let category = Category(id: 10, name: "Medical", emoji: "🚑", direction: .outcome)

        let transaction = Transaction(id: 100, account: account, category: category, amount: 50.5, transactionDate: Date(), comment: "Pills", createdAt: Date(), updatedAt: Date())
        let jsonObject = transaction.jsonObject
        guard let parsed = Transaction.parse(jsonObject: jsonObject) else {
            XCTFail("failed")
            return
        }
        XCTAssertEqual(parsed.id, transaction.id)
        XCTAssertEqual(parsed.account.id, transaction.account.id)
        XCTAssertEqual(parsed.category.id, transaction.category.id)
        XCTAssertEqual(parsed.amount, transaction.amount)
        XCTAssertEqual(parsed.comment, transaction.comment)
        XCTAssertEqual(parsed.amount, parsed.amount)
    }
    
    func parseIncalid() {
        let invalid: [String: Any] = ["invalidKey": "invalidValue"]
        let res = Transaction.parse(jsonObject: invalid)
        XCTAssertNil(res)
    }
}
