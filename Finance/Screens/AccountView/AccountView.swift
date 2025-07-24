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
                let balanceDouble = abs((entry.balance as NSDecimalNumber).doubleValue)
                let barHeight = entry.balance == 0 ? 50.0 : balanceDouble
                let barColor: Color = {
                    if entry.balance == 0 {
                        return Color.gray.opacity(0.7)
                    } else {
                        return entry.balance > 0 ? .green : .red
                    }
                }()

                BarMark(
                    x: .value("Date", entry.date, unit: period == .daily ? .day : .month),
                    y: .value("Balance", barHeight)
                )
                .foregroundStyle(barColor)
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
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let locationX = value.location.x - geometry[proxy.plotAreaFrame].origin.x
                                if let date: Date = proxy.value(atX: locationX) {
                                    let calendar = Calendar.current
                                    let matchedEntry: BalanceBar?
                                    switch period {
                                    case .daily:
                                        matchedEntry = balances.first { calendar.isDate($0.date, inSameDayAs: date) }
                                    case .monthly:
                                        matchedEntry = balances.first {
                                            calendar.component(.year, from: $0.date) == calendar.component(.year, from: date) &&
                                            calendar.component(.month, from: $0.date) == calendar.component(.month, from: date)
                                        }
                                    }
                                    if let entry = matchedEntry {
                                        withAnimation(.linear(duration: 0.3)) {
                                            viewModel.selectedEntry = entry
                                        }
                                    }
                                }
                            }
                            .onEnded { _ in
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    withAnimation(.linear(duration: 0.3)) {
                                        viewModel.selectedEntry = nil
                                    }
                                }
                            }
                    )
                    .overlay {
                        if let selectedEntry = viewModel.selectedEntry,
                           let xPosition = proxy.position(forX: selectedEntry.date) {
                            let barColor: Color = selectedEntry.balance == 0 ? .gray : (selectedEntry.balance > 0 ? .green : .red)

                            Text("\(selectedEntry.balance, format: .number) \(viewModel.currency)")
                                .font(.caption)
                                .padding(6)
                                .background(barColor)
                                .cornerRadius(6)
                                .foregroundColor(.white)
                                .position(
                                    x: xPosition + geometry[proxy.plotAreaFrame].origin.x,
                                    y: geometry[proxy.plotAreaFrame].origin.y)
                                .transition(.scale.combined(with: .opacity))
                                .animation(.easeInOut(duration: 0.3), value: viewModel.selectedEntry?.id)
                        }
                    }
            }
        }
        .frame(height: 200)
        .padding(.vertical)
        .background(Color(.systemGray6))
        .animation(.easeInOut(duration: 0.4), value: viewModel.selectedPeriod)
    }
}



