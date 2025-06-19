//
//  IncomeView.swift
//  Finance
//
//  Created by Stepan Polyakov on 16.06.2025.
//

import SwiftUI

struct IncomeView: View {
    @StateObject private var viewModel: IncomeViewModel
    
    init(transactionsService: TransactionsService, categoriesService: CategoriesService, direction: Direction) {
        _viewModel = StateObject(wrappedValue: IncomeViewModel(transactionService: transactionsService, categoriesService: categoriesService, direction: direction))
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("Bcего")
                        Spacer()
                        Text("\(viewModel.total) ₽")
                    }
                }
                
                Section(header: Text("ОПЕРАЦИИ")) {
                    ForEach(viewModel.items, id: \.0.id) { transaction, category in
                        TransactionRow(transaction: transaction, category: category)
                    }
                }
            }
            .navigationTitle(viewModel.directionText)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        HistoryView(
                            transactionsService: viewModel.transactionService,
                            categoriesService: viewModel.categoriesService,
                            direction: viewModel.direction
                        )
                    } label: {
                        Image(systemName: "clock")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .task {
                await viewModel.load()
            }
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    let category: Category
    
    var body: some View {
        HStack {
            Text("\(category.emoji)")
                .padding(5)
                .background(Color.accentColor.opacity(0.2))
                .clipShape(Circle())
            
            Text(category.name)
            
            Spacer()
            
            Text("\(transaction.amount) ₽")
            Image(systemName: "chevron.right")
                .foregroundStyle(Color.gray)
        }
    }
}

