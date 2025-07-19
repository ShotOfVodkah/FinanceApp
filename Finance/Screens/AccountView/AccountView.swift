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

    @StateObject private var viewModel: AccountViewModel

    init(bankAccountModel: BankAccountsService) {
        _viewModel = StateObject(wrappedValue: AccountViewModel(bankAccountService: bankAccountModel))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6)
                    .edgesIgnoringSafeArea(.all)
                
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                    } else {
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
                            .padding()
                        }
                    }
                }
                .transition(.opacity)
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .navigationTitle("Мой счёт")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if isEditing {
                            Task {
                                await viewModel.updateAccount()
                            }
                        } else {
                            viewModel.localBalanceText = viewModel.account?.balance.description ?? ""
                            viewModel.formattedBalanceText = viewModel.localBalanceText
                            viewModel.localCurrency = Currency(rawValue: viewModel.account?.currency ?? "") ?? .rub
                        }
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
            .refreshable {
                Task {
                    await viewModel.refresh()
                }
            }
            .confirmationDialog("Выберите валюту", isPresented: $showCurrency, titleVisibility: .visible) {
                ForEach(Currency.allCases, id: \.self) { currency in
                    Button {
                        viewModel.localCurrency = currency
                    } label: {
                        Text(currency.fullName)
                    }
                }
            }
            .alert("Ошибка", isPresented: .constant(viewModel.error != nil)) {
                Button("Ок", role: .cancel) {
                    viewModel.error = nil
                }
            } message: {
                Text(viewModel.error ?? "Неизвестная ошибка")
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
                    Text("\(viewModel.formattedBalanceText) \(viewModel.localCurrency.symbol)")
                        .foregroundColor(.gray)
                        .opacity(showTextField ? 0.0 : 1.0)
                }
            }
            if showTextField {
                HStack {
                    TextField("Изменить баланс", text: $viewModel.localBalanceText)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)

                    Button("Готово") {
                        Task {
                            viewModel.formatBalanceText() 
                            withAnimation(.easeInOut) {
                                showTextField = false
                            }
                        }
                    }
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                }
            }
        }
        .padding()
        .background(Color.white)
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
                Text(viewModel.localCurrency.symbol)
                    .foregroundColor(.gray)
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 15))
        }
    }
}



