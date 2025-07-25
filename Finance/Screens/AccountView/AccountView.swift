//
//  BankAccountView.swift
//  Finance
//
//  Created by Stepan Polyakov on 23.06.2025.
//

import SwiftUI
import Charts

struct AccountView: View {
    @State private var isEditing: Bool = false
    @State private var showCurrency = false
    @State private var showTextField = false
    @State private var deviceShaken = false
    @State private var selectedEntry: BalanceBar?
    private func isSelected(_ entry: BalanceBar) -> Bool {
        selectedEntry?.id == entry.id
    }

    @StateObject private var viewModel: AccountViewModel

    init(bankAccountModel: BankAccountsService, transactionService: TransactionsService, categoriesService: CategoriesService) {
        _viewModel = StateObject(wrappedValue: AccountViewModel(bankAccountService: bankAccountModel, transactionService: transactionService, categoriesService: categoriesService))
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
                                        pickerView()
                                        balanceChart(balances: viewModel.currentBalances, period: viewModel.selectedPeriod)
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
    
    private func pickerView() -> some View {
        HStack {
            Text("Период")
            Spacer()
            Picker("", selection: $viewModel.selectedPeriod) {
                ForEach(AccountViewModel.StatisticsPeriod.allCases) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(DefaultPickerStyle())
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color.white)
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

    @ViewBuilder
    private func balanceChart(balances: [BalanceBar], period: AccountViewModel.StatisticsPeriod) -> some View {
        Chart {
            ForEach(balances) { entry in
                let amount = abs((entry.balance as NSDecimalNumber).doubleValue)
                let height = entry.balance == 0 ? 50.0 : amount
                let color: Color = entry.balance == 0 ? .gray.opacity(0.7) :
                                  (entry.balance > 0 ? .green : .red)

                BarMark(
                    x: .value("Date", entry.date, unit: period == .daily ? .day : .month),
                    y: .value("Balance", height)
                )
                .foregroundStyle(color)
                .cornerRadius(10)
            }
        }
        .chartYAxis(.hidden)
        .chartXAxis {
            if period == .daily {
                AxisMarks(values: .stride(by: .day, count: 7)) { value in
                    AxisValueLabel(format: .dateTime.day().month(.twoDigits), centered: true)
                }
            } else {
                AxisMarks(values: .stride(by: .month, count: 3)) { value in
                    AxisValueLabel(format: .dateTime.month(.abbreviated).year(.twoDigits), centered: true)
                }
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let location = value.location.x - geometry[proxy.plotAreaFrame].origin.x
                                if let date: Date = proxy.value(atX: location) {
                                    selectedEntry = balances.min {
                                        abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                                    }
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.easeOut(duration: 0.3)) {
                                    selectedEntry = nil
                                }
                            }
                    )
                if let selected = selectedEntry,
                    let xPosition = proxy.position(forX: selected.date) {
                    let color: Color = selected.balance == 0 ? .gray.opacity(0.7) :
                                        (selected.balance > 0 ? .green : .red)
                    Text("\(selected.balance, format: .number) \(viewModel.currency)")
                        .font(.caption2)
                        .padding(4)
                        .background(color)
                        .cornerRadius(4)
                        .foregroundColor(.white)
                        .position(
                            x: xPosition + geometry[proxy.plotAreaFrame].origin.x,
                            y: geometry[proxy.plotAreaFrame].minY - 10
                        )
                        .transition(.opacity)
                }
            }
        }
        .frame(height: 200)
        .padding(.vertical)
        .background(Color(.systemGray6))
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: viewModel.selectedPeriod)
    }
}



