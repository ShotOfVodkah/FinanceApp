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
    
    init(transactionsService: TransactionsService, categoriesService: CategoriesService, direction: Direction) {
        _viewModel = StateObject(wrappedValue: HistoryViewModel(transactionService: transactionsService, categoriesService: categoriesService, direction: direction))
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
                    TransactionRow(transaction: transaction, category: category)
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
            Task { await viewModel.check_date(flag: false) }
        }
        .onChange(of: viewModel.to) { _ in
            Task { await viewModel.check_date(flag: true) }
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
                Button(action: {
                    
                }) {
                    Image(systemName: "document")
                        .foregroundStyle(.gray)
                }
            }
        }
    }
}
