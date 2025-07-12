//
//  IncomeView.swift
//  Finance
//
//  Created by Stepan Polyakov on 16.06.2025.
//

import SwiftUI

struct TransactionsListView: View {
    @StateObject private var viewModel: TransactionsListViewModel
    
    init(transactionsService: TransactionsService, categoriesService: CategoriesService, direction: Direction, bankAccountService: BankAccountsService) {
        _viewModel = StateObject(wrappedValue: TransactionsListViewModel(transactionService: transactionsService, categoriesService: categoriesService, direction: direction, bankAccountService: bankAccountService))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                List {
                    Section {
                        HStack {
                            Text("Bcего")
                            Spacer()
                            Text("\(viewModel.total) \(viewModel.symbol)")
                        }
                    }
                    
                    Section(header: Text("ОПЕРАЦИИ")) {
                        ForEach(viewModel.items, id: \.0.id) { transaction, category in
                            TransactionRow(transaction: transaction, category: category, symbol: viewModel.symbol)
                                .onTapGesture {
                                    viewModel.selectedTransaction = (transaction, category)
                                    viewModel.sheet = true
                                }
                        }
                    }
                }
                .navigationTitle(viewModel.directionText)
                .listStyle(.insetGrouped)
                .task {
                    await viewModel.load()
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            viewModel.sheet = true
                            viewModel.selectedTransaction = nil
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.accentColor)
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        HistoryView(
                            transactionsService: viewModel.transactionService,
                            categoriesService: viewModel.categoriesService,
                            direction: viewModel.direction,
                            bankAccountService: viewModel.bankAccountService
                        )
                    } label: {
                        Image(systemName: "clock")
                    }
                }
            }
            .fullScreenCover(isPresented: $viewModel.sheet, onDismiss: {
                Task { await viewModel.load() }
            }) {
                EditDeleteView(transactionsService: viewModel.transactionService, categoriesService: viewModel.categoriesService, direction: viewModel.direction, bankAccountService: viewModel.bankAccountService, selectedTransaction: viewModel.selectedTransaction)
            }
        }
    }
}



struct TransactionRow: View {
    let transaction: Transaction
    let category: Category
    let symbol: String
    
    var body: some View {
        HStack {
            Text("\(category.emoji)")
                .padding(5)
                .background(Color.accentColor.opacity(0.2))
                .clipShape(Circle())
            
            Text(category.name)
            
            Spacer()
            
            Text("\(transaction.amount) \(symbol)")
            Image(systemName: "chevron.right")
                .foregroundStyle(.gray)
        }
    }
}

