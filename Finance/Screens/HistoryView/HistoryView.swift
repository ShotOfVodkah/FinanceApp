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
        VStack(alignment: .leading) {
            HStack {
                Button(action: {dismiss()}) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Назад")
                    }
                    .foregroundStyle(Color.gray)
                }
                Spacer()
                Button {
                    
                } label: {
                    Image(systemName: "document")
                        .foregroundStyle(Color.gray)
                }
            }
            .padding()
            
            Text("Моя история")
                .font(.title)
                .bold()
            
            VStack {
                HStack {
                    DatePicker("Начало", selection: $viewModel.from, in: ...Date(), displayedComponents: .date)
                }
                
                Divider()
                
                HStack {
                    DatePicker("Конец", selection: $viewModel.to, in: ...Date(), displayedComponents: .date)
                }
                
                Divider()
                
                HStack {
                    Text("Cумма")
                    Spacer()
                    Text("\(viewModel.total) ₽")
                }
                .padding(.vertical, 5)
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
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGray6))
        .navigationBarBackButtonHidden(true)
        .task {
            await viewModel.load()
        }
        .onChange(of: viewModel.from) { newValue in
            viewModel.from = Calendar.current.startOfDay(for: newValue)
            Task { await viewModel.load() }
        }
        .onChange(of: viewModel.to) { newValue in
            viewModel.to = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: newValue)!
            Task { await viewModel.load() }
        }

    }
}
