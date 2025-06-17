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
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Spacer()
                    NavigationLink {
                        HistoryView(
                            transactionsService: viewModel.transactionService,
                            categoriesService: viewModel.categoriesService,
                            direction: viewModel.direction
                        )
                    } label: {
                        Image(systemName: "clock")
                            .foregroundStyle(.gray)
                            .imageScale(.large)
                    }
                }
                
                Text(viewModel.directionText)
                    .font(.title)
                    .bold()
                
                HStack {
                    Text("Bcего")
                    Spacer()
                    Text("\(viewModel.total) ₽")
                }
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                
                Text("ОПЕРАЦИИ")
                    .foregroundStyle(Color.gray)
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.items, id: \.0.id) { transaction, category in
                            TransactionRow(transaction: transaction, category: category)
                                .padding(.vertical, 10)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGray6))
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

