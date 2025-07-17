//
//  EditDeleteViewModel.swift
//  Finance
//
//  Created by Stepan Polyakov on 09.07.2025.
//


import Foundation

@MainActor
final class EditDeleteViewModel: ObservableObject {
    let transactionService: TransactionsService
    let categoriesService: CategoriesService
    let bankAccountService: BankAccountsService
    let direction: Direction

    var isEditing: Bool = false
    private var transactionId: Int?
    var categories: [Category] = []

    @Published var amountText: String = ""
    var amount: Decimal? = nil
    var prevAmount: Decimal? = nil

    @Published var selectedDate: Date 
    @Published var selectedTime: Date
    var fullDate: Date

    @Published var description: String = ""
    @Published var selectedCategory: Category? = nil

    @Published var isChoosingCategory = false
    @Published var isShowingAlert = false

    @Published var isLoading = false
    @Published var error: String?

    var buttonText: String {
        isEditing ? "Сохранить" : "Создать"
    }

    var directionText: String {
        direction == .income ? "Мои доходы" : "Мои расходы"
    }

    var deleteText: String {
        direction == .income ? "Удалить доход" : "Удалить расход"
    }

    init(transactionService: TransactionsService, categoriesService: CategoriesService, direction: Direction, bankAccountService: BankAccountsService, selectedTransaction: (Transaction, Category)? = nil) {
        self.categoriesService = categoriesService
        self.transactionService = transactionService
        self.direction = direction
        self.bankAccountService = bankAccountService

        if let transaction = selectedTransaction {
            amountText = "\(transaction.0.amount)"
            selectedDate = transaction.0.transactionDate
            selectedTime = transaction.0.transactionDate
            description = transaction.0.comment ?? ""
            amount = transaction.0.amount
            prevAmount = transaction.0.amount
            fullDate = transaction.0.transactionDate
            selectedCategory = transaction.1
            transactionId = transaction.0.id
            isEditing = true
        } else {
            selectedDate = Date()
            selectedTime = Date()
            fullDate = Date()
        }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            categories = try await categoriesService.getSpecific(dir: direction)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func save() async -> Bool {
        guard !isLoading else { return false }

        isLoading = true
        defer { isLoading = false }

        do {
            let account = try await bankAccountService.getCurrentAccountId()
            if isEditing {
                try await transactionService.editTransaction(id: transactionId ?? 0, categoryId: selectedCategory!.id, accountId: account, amount: amount ?? 0.00, transactionDate: fullDate, comment: description)
                return true
            } else {
                guard let amount, let selectedCategory else {
                    isShowingAlert = true
                    return false
                }
                
                //tmp
                print("Sending transaction with date: \(fullDate)")
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                print("Formatted date: \(formatter.string(from: fullDate))")
                //tmpEnd
                
                try await transactionService.addTransaction(transaction: Transaction(id: 0, account: account, category: selectedCategory.id, amount: amount, transactionDate: fullDate, comment: description, createdAt: Date(), updatedAt: Date()))
                return true
            }
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func delete() async {
        guard !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            if let amt = amount, let id = transactionId {
                try await transactionService.deleteTransaction(id: id)
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func checkInput(num: String) {
        let locale = Locale.current
        let decimalSeparator = locale.decimalSeparator ?? "."
        let allowedCharacters = CharacterSet(charactersIn: "0123456789\(decimalSeparator)")
        let filtered = String(num.unicodeScalars.filter { allowedCharacters.contains($0) })
        let components = filtered.components(separatedBy: decimalSeparator)
        guard components.count <= 2 else { return }
        var sanitized = filtered
        if sanitized.hasPrefix(decimalSeparator) {
            sanitized = "0" + sanitized
        }
        if let decimalValue = Decimal(string: sanitized, locale: locale) {
            amountText = sanitized
            amount = decimalValue
        } else {
            amountText = ""
            amount = nil
        }
    }

    func updateDate() {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let existingNanoseconds = calendar.dateComponents([.nanosecond], from: fullDate).nanosecond
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: selectedTime)
        var mergedComponents = DateComponents()
        mergedComponents.year = dateComponents.year
        mergedComponents.month = dateComponents.month
        mergedComponents.day = dateComponents.day
        mergedComponents.hour = timeComponents.hour
        mergedComponents.minute = timeComponents.minute
        mergedComponents.second = timeComponents.second
        mergedComponents.nanosecond = existingNanoseconds
        fullDate = calendar.date(from: mergedComponents) ?? Date()
    }

    func updateTime() {
        updateDate()
    }
}

