//
//  TransactionFileCache.swift
//  FinanceApp
//
//  Created by Stepan Polyakov on 09.06.2025.
//

import Foundation

class TransactionFileCache {
    private(set) var transactions: [Transaction]
    
    init() {
        self.transactions = []
    }

    func add(transaction: Transaction) {
        if !transactions.contains(where: {$0.id == transaction.id}) {
            transactions.append(transaction)
        }
    }
    
    func remove(id: Int) {
        transactions.removeAll( where: { $0.id == id })
    }
    
    func save(path: URL) throws {
        let arr: [Any] = transactions.map {$0.jsonObject}
        let file = try JSONSerialization.data(withJSONObject: arr)
        try file.write(to: path)
    }
    
    func load(from fileURL: URL) throws {
        transactions.removeAll() // ???
        
        let file = try Data(contentsOf: fileURL)
        guard let arr = try JSONSerialization.jsonObject(with: file, options: []) as? [Any] else {
            throw NSError(domain: "", code: 1)
        }
        let parsed = arr.compactMap { Transaction.parse(jsonObject: $0) }
        for transaction in parsed {
            if !transactions.contains(where: { $0.id == transaction.id }) {
                transactions.append(transaction)
            }
        }
    }
}
