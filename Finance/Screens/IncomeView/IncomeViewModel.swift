//
//  IncomeViewModel.swift
//  Finance
//
//  Created by Stepan Polyakov on 16.06.2025.
//

import Foundation

@MainActor
final class TransactionsListViewModel: ObservableObject {
    @Published var items: [(Transaction, Category)] = []
    @Published var total: Decimal = 0
    var directionText: String {
        switch direction {
        case .income: return "Доходы сегодня"
        case .outcome: return "Расходы сегодня"
        }
    }
    
    let transactionService: TransactionsService
    let categoriesService: CategoriesService
    let direction: Direction
    
    init(transactionService: TransactionsService, categoriesService: CategoriesService, direction: Direction) {
        self.categoriesService = categoriesService
        self.transactionService = transactionService
        self.direction = direction
    }
    
    func load() async {
        items = []
        total = 0
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        
        let transactions = await transactionService.getTransactions(from: start, to: end)
        let categories = await categoriesService.getSpecific(dir: direction)
        
        for transaction in transactions {
            if let category = categories.first(where: { $0.id == transaction.categoryId }) {
                items.append((transaction, category))
                total += transaction.amount
            }
        }
    }
}
