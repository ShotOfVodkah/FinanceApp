//
//  HistoryViewModel.swift
//  Finance
//
//  Created by Stepan Polyakov on 17.06.2025.
//

import Foundation

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var items: [(Transaction, Category)] = []
    @Published var total: Decimal = 0
    @Published var from: Date
    @Published var to: Date
    
    private let transactionService: TransactionsService
    private let categoriesService: CategoriesService
    private let direction: Direction
    
    init(transactionService: TransactionsService, categoriesService: CategoriesService, direction: Direction) {
        self.categoriesService = categoriesService
        self.transactionService = transactionService
        self.direction = direction
        self.to = Calendar.current.date(bySettingHour: 23, minute: 59, second: 0, of: Date())!
        self.from = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .month, value: -1, to: Date())!)
    }
    
    func load() async {
        items = []
        total = 0
        
        let transactions = await transactionService.getTransactions(from: from, to: to)
        let categories = await categoriesService.getSpecific(dir: direction)
        
        for transaction in transactions {
            if let category = categories.first(where: { $0.id == transaction.categoryId }) {
                items.append((transaction, category))
                total += transaction.amount
            }
        }
    }
    
    func check_date(to_changed: Bool) async {
        var from_date = Calendar.current.startOfDay(for: from)
        var to_date = Calendar.current.startOfDay(for: to)
        
        guard (to_changed && from_date > to_date) || (!to_changed && to_date < from_date) else { return }
        
        if from_date > to_date && to_changed {
            from_date = to_date
        } else if to_date < from_date {
            to_date = from_date
        }
        self.from = from_date
        self.to = Calendar.current.date(bySettingHour: 23, minute: 59, second: 0, of: to_date)!
        await load()
    }
    
    @Published var selectedSope: FilterType = .date
    
    enum FilterType: String, CaseIterable {
        case date = "Дата"
        case amount = "Сумма"
    }
    
    var filteredItems: [(Transaction, Category)] {
        switch selectedSope {
        case .date:
            return items.sorted(by: { $0.0.transactionDate > $1.0.transactionDate })
        case .amount:
            return items.sorted(by: { $0.0.amount > $1.0.amount })
        }
    }
    
}
