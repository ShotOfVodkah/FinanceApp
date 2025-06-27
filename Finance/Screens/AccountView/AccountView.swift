//
//  BankAccountView.swift
//  Finance
//
//  Created by Stepan Polyakov on 23.06.2025.
//

import SwiftUI

struct AccountView: View {
    
    @State private var isEditing: Bool = false
    @State private var showCurrency = false
    @State private var showTextField = false
    @State private var deviceShaken = false
    @State private var newBalanceText = ""
    
    @StateObject private var viewModel: AccountViewModel
    
    init(bankAccountModel: BankAccountsService) {
        _viewModel = StateObject(wrappedValue: AccountViewModel(bankAccountService: bankAccountModel))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let account = viewModel.account {
                            if isEditing {
                                balanceEdit(account: account)
                                currencyEdit()
                            } else {
                                balanceView(account: account)
                                currencyView()
                            }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color(.systemGray6))
            .navigationTitle("Мой счет")
            .refreshable {
                await viewModel.refresh()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation(.easeInOut) {
                            isEditing.toggle()
                        }
                    } label: {
                        Text(isEditing ? "Сохранить" : "Редактировать")
                    }
                }
            }
            .task {
                await viewModel.load()
            }
            .confirmationDialog("Выберите валюту", isPresented: $showCurrency, titleVisibility: .visible) {
                ForEach(Currency.allCases, id: \.self) { currency in
                    Button {
                        Task {
                            await viewModel.updateCurrency(newCurrency: currency.rawValue)
                        }
                    } label: {
                        Text(currency.fullName)
                    }
                }
            }
        }
    }
    
    private func balanceView(account: BankAccount) -> some View {
        HStack {
            Text("💰  Баланс")
            Spacer()
            Text("\(account.balance) \(viewModel.currency)")
                .spoiler(isOn: $deviceShaken)
        }
        .modifier(ShakeGestureViewModifier {
            withAnimation {
                deviceShaken.toggle()
            }
        })
        .padding()
        .background(Color.accentColor)
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }
    
    private func currencyView() -> some View {
        HStack {
            Text("Валюта")
            Spacer()
            Text(viewModel.currency)
        }
        .padding()
        .background(Color.accentColor.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }
    
    private func balanceEdit(account: BankAccount) -> some View {
        VStack {
            Button {
                withAnimation(.easeInOut) {
                    showTextField = true
                }
            } label: {
                HStack {
                    Text("💰  Баланс")
                        .foregroundColor(.black)
                    Spacer()
                    Text("\(account.balance) \(viewModel.currency)")
                        .foregroundColor(.gray)
                        .opacity(showTextField ? 0.0 : 1.0)
                }
            }
            if showTextField {
                HStack {
                    TextField("Изменить баланc", text: $newBalanceText)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)

                    Button("Готово") {
                        Task {
                            await viewModel.updateBalance(input: newBalanceText)
                            newBalanceText = ""
                            withAnimation(.easeInOut) {
                                showTextField = false
                            }
                        }
                    }
                    .padding()
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                }
            }
        }
        .padding()
        .background(Color.white)
        .foregroundStyle(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }
    
    private func currencyEdit() -> some View {
        Button {
            showCurrency.toggle()
        } label: {
            HStack {
                Text("Валюта")
                    .foregroundColor(.black)
                Spacer()
                Text(viewModel.currency)
                    .foregroundColor(.gray)
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white)
            .foregroundStyle(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 15))
        }
    }
}


