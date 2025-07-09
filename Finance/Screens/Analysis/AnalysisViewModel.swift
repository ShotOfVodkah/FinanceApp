//
//  AnalysisViewModel.swift
//  Finance
//
//  Created by Stepan Polyakov on 08.07.2025.
//

import Foundation
final class AnalysisViewModel {
    var items: [(Transaction, Category)] = []
    var total: Decimal = 0
    var from: Date {
        didSet {
            if to < from {
                to = Calendar.current.date(bySettingHour: 23, minute: 59, second: 0, of: from)!
            }
        }
    }
    var to: Date {
        didSet {
            let toDateStart = Calendar.current.startOfDay(for: to)
            to = Calendar.current.date(bySettingHour: 23, minute: 59, second: 0, of: toDateStart)!
            if from > to {
                from = Calendar.current.startOfDay(for: to)
            }
        }
    }

    private let transactionService: TransactionsService
    private let categoriesService: CategoriesService
    private let direction: Direction
    
    var onDatesUpdated: (() -> Void)?
    var onDataLoaded: (() -> Void)?

    init(transactionService: TransactionsService, categoriesService: CategoriesService, direction: Direction) {
        self.transactionService = transactionService
        self.categoriesService = categoriesService
        self.direction = direction
        self.to = Calendar.current.date(bySettingHour: 23, minute: 59, second: 0, of: Date())!
        self.from = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .month, value: -1, to: Date())!)
    }

    func updateFromDate(_ date: Date) {
        from = Calendar.current.startOfDay(for: date)
        onDatesUpdated?()
        loadData()
    }
    
    func updateToDate(_ date: Date) {
        to = date
        onDatesUpdated?()
        loadData()
    }
    
    func loadData() {
        Task {
            self.items = []
            self.total = 0

            let transactions = await transactionService.getTransactions(from: from, to: to)
            let categories = await categoriesService.getSpecific(dir: direction)

            for transaction in transactions {
                if let category = categories.first(where: { $0.id == transaction.categoryId }) {
                    self.items.append((transaction, category))
                    self.total += transaction.amount
                }
            }

            DispatchQueue.main.async {
                self.onDataLoaded?()
            }
        }
    }
    
    func percentage(for transaction: Transaction) -> String {
        guard total != 0 else { return "0%" }
        let percent = (transaction.amount as NSDecimalNumber)
            .dividing(by: total as NSDecimalNumber)
            .multiplying(by: 100)
            .doubleValue
        return String(format: "%.1f%%", percent)
    }
}
