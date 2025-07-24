//
//  BankAccountViewModel.swift
//  Finance
//
//  Created by Stepan Polyakov on 23.06.2025.
//

import Foundation
import Charts
import SwiftUI

struct BalanceBar: Identifiable {
    let id = UUID()
    let date: Date
    let balance: Decimal
}

@MainActor
final class AccountViewModel: ObservableObject {
    private let bankAccountService: BankAccountsService
    private let transactionService: TransactionsService
    private let categoriesService: CategoriesService

    @Published var account: BankAccount?
    @Published var isLoading = false
    @Published var isReloadingBalances = false
    @Published var error: String?
    
    enum StatisticsPeriod: String, CaseIterable, Identifiable {
        case daily = "Дни"
        case monthly = "Месяцы"
        var id: String { self.rawValue }
    }
    
    @Published var selectedPeriod: StatisticsPeriod = .daily
    @Published private var dailyBalances: [BalanceBar] = []
    @Published private var monthlyBalances: [BalanceBar] = []
    @Published var selectedEntry: BalanceBar?
    
    private var allTransactions: [Transaction] = []
    private var allCategories: [Category] = []

    var currentBalances: [BalanceBar] {
        selectedPeriod == .daily ? dailyBalances : monthlyBalances
    }

    var currency: String {
        guard let code = account?.currency,
              let currency = Currency(rawValue: code) else { return "" }
        return currency.symbol
    }
    
    @Published var localBalanceText: String = ""
    @Published var formattedBalanceText: String = ""
    @Published var localCurrency: Currency = .rub

    init(bankAccountService: BankAccountsService,
         transactionService: TransactionsService,
         categoriesService: CategoriesService) {
        self.bankAccountService = bankAccountService
        self.categoriesService = categoriesService
        self.transactionService = transactionService
    }

    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            account = try await bankAccountService.getAccount()
            
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let startDate = calendar.date(byAdding: .month, value: -23, to: today)!
            let endDate = calendar.date(byAdding: .day, value: 1, to: today)!

            let categories = try await categoriesService.getAll()
            let transactions = try await transactionService.getTransactions(from: startDate, to: endDate)

            self.allCategories = categories
            self.allTransactions = transactions

            async let dailyTask = loadBalances(for: .daily)
            async let monthlyTask = loadBalances(for: .monthly)
            let (daily, monthly) = await (try dailyTask, try monthlyTask)
            
            withAnimation(.spring()) {
                self.dailyBalances = daily
                self.monthlyBalances = monthly
            }

        } catch {
            self.error = error.localizedDescription
        }
    }

    private func loadBalances(for period: StatisticsPeriod) throws -> [BalanceBar] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var results: [BalanceBar] = []

        let grouped: [Date: [Transaction]] = {
            switch period {
            case .daily:
                return Dictionary(grouping: allTransactions) { calendar.startOfDay(for: $0.transactionDate) }
            case .monthly:
                return Dictionary(grouping: allTransactions) {
                    let comps = calendar.dateComponents([.year, .month], from: $0.transactionDate)
                    return calendar.date(from: comps)!
                }
            }
        }()

        switch period {
        case .daily:
            for offset in (0..<30).reversed() {
                let day = calendar.date(byAdding: .day, value: -offset, to: today)!
                let dayTransactions = grouped[day] ?? []
                let total = calculateTotal(for: dayTransactions)
                results.append(BalanceBar(date: day, balance: total))
            }
            
        case .monthly:
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
            for offset in (0..<24).reversed() {
                let month = calendar.date(byAdding: .month, value: -offset, to: monthStart)!
                let monthTransactions = grouped[month] ?? []
                let total = calculateTotal(for: monthTransactions)
                results.append(BalanceBar(date: month, balance: total))
            }
        }
        
        return results
    }
    
    private func calculateTotal(for transactions: [Transaction]) -> Decimal {
        transactions.reduce(Decimal.zero) { total, tx in
            guard let category = allCategories.first(where: { $0.id == tx.categoryId }) else {
                return total
            }
            return category.direction == .income ? total + tx.amount : total - tx.amount
        }
    }

    func refresh() async {
        await load()
    }

    func updateAccount() async {
        guard let amount = Decimal(string: formattedBalanceText) else { return }

        if amount == account?.balance && localCurrency.rawValue == account?.currency {return}
        
        isLoading = true
        error = nil
        defer { isLoading = false }
        print(localCurrency.rawValue)
        do {
            try await bankAccountService.updateAccount(amount: amount, newCurrencyCode: localCurrency.rawValue)
            account = try await bankAccountService.getAccount()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func formatBalanceText() {
            let filtered = localBalanceText
                .filter { "0123456789,.".contains($0) }
                .replacingOccurrences(of: ",", with: ".")
            let components = filtered.components(separatedBy: ".")
            if components.count > 1 {
                formattedBalanceText = components[0] + "." + components.dropFirst().joined()
            } else {
                formattedBalanceText = filtered
            }
            localBalanceText = formattedBalanceText
        }
}
