//
//  HistoryView.swift
//  Finance
//
//  Created by Stepan Polyakov on 17.06.2025.
//

import SwiftUI

struct HistoryView: View {
    
    @StateObject private var viewModel: HistoryViewModel
    @Environment(\.dismiss) var dismiss
    
    init(transactionsService: TransactionsService, categoriesService: CategoriesService, direction: Direction, bankAccountService: BankAccountsService) {
        _viewModel = StateObject(wrappedValue: HistoryViewModel(transactionService: transactionsService, categoriesService: categoriesService, direction: direction, bankAccountService: bankAccountService))
    }
    
    var body: some View {
        List {
            Section {
                DatePicker("Начало", selection: $viewModel.from, in: ...Date(), displayedComponents: .date)
                
                DatePicker("Конец", selection: $viewModel.to, in: ...Date(), displayedComponents: .date)
                
                HStack {
                    Text("Сортировка")
                    Spacer()
                    Picker("", selection: $viewModel.selectedSope) {
                        ForEach(HistoryViewModel.FilterType.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(DefaultPickerStyle())
                }
                
                HStack {
                    Text("Cумма")
                    Spacer()
                    Text("\(viewModel.total) ₽")
                }
            }
            
            Section(header: Text("ОПЕРАЦИИ")) {
                ForEach(viewModel.filteredItems, id: \.0.id) { transaction, category in
                    TransactionRow(transaction: transaction, category: category, symbol: viewModel.symbol)
                        .onTapGesture {
                            viewModel.selectedTransaction = (transaction, category)
                            viewModel.sheet = true
                        }
                }
            }
        }
        .navigationTitle("Моя история")
        .navigationBarBackButtonHidden(true)
        .listStyle(.insetGrouped)
        .task {
            await viewModel.load()
        }
        .background(Color(.systemGray6))
        .onChange(of: viewModel.from) { _ in
            viewModel.check_date(to_changed: false)
            Task { await viewModel.load() }
        }
        .onChange(of: viewModel.to) { _ in
            viewModel.check_date(to_changed: true)
            Task { await viewModel.load() }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Label("Назад", systemImage: "chevron.left")
                        .labelStyle(.titleAndIcon)
                        .foregroundStyle(.gray)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    AnalysisView(transactionService: viewModel.transactionService,
                                 categoriesService: viewModel.categoriesService,
                                 direction: viewModel.direction)
                } label: {
                    Image(systemName: "document")
                        .foregroundStyle(.gray)
                }

            }
        }
        .fullScreenCover(isPresented: $viewModel.sheet, onDismiss: {
            Task { await viewModel.load() }
        }) {
            if let selected = viewModel.selectedTransaction {
                EditDeleteView(transactionsService: viewModel.transactionService, categoriesService: viewModel.categoriesService, direction: viewModel.direction, bankAccountService: viewModel.bankAccountService, selectedTransaction: selected)
            }
        }

    }
}
