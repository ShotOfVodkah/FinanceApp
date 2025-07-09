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
    
    var buttonText: String {
        if isEditing {
            return "Сохранить"
        } else {
            return "Создать"
        }
    }
    var directionText: String {
        switch direction {
        case .income: return "Мои доходы"
        case .outcome: return "Мои расходы"
        }
    }
    var deleteText: String {
        switch direction {
        case .income: return "Удалить доход"
        case .outcome: return "Удалить расход"
        }
    }
    
    @Published var amountText: String = ""
    var amount: Decimal? = nil
    var prevAmount: Decimal? = nil
    
    @Published var selectedDate: Date = Date()
    @Published var selectedTime: Date = Date()
    var fullDate: Date = Date()
    
    @Published var description: String = ""
    @Published var selectedCategory: Category? = nil
    
    private var transactionId: Int?
    
    @Published var isChoosingCategory: Bool = false
    @Published var isShowingAlert: Bool = false
    
    var categories: [Category] = []
    
    init(transactionService: TransactionsService, categoriesService: CategoriesService, direction: Direction, bankAccountService: BankAccountsService, selectedTransaction: (Transaction, Category)? = nil) {
        self.categoriesService = categoriesService
        self.transactionService = transactionService
        self.direction = direction
        self.bankAccountService = bankAccountService
        if let transaction = selectedTransaction {
            self.amountText = "\(transaction.0.amount)"
            self.selectedDate = transaction.0.transactionDate
            self.selectedTime = transaction.0.transactionDate
            self.description = transaction.0.comment ?? ""
            self.amount = transaction.0.amount
            self.prevAmount = transaction.0.amount
            self.fullDate = transaction.0.transactionDate
            self.selectedCategory = transaction.1
            self.transactionId = transaction.0.id
            self.isEditing = true
        }
        
    }
    
    func load() async {
        await categories = categoriesService.getSpecific(dir: direction)
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
        let date = Calendar.current.startOfDay(for: selectedDate)
        let time = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
        fullDate = Calendar.current.date(byAdding: time, to: date) ?? fullDate
    }
    
    func updateTime() {
        let date = Calendar.current.startOfDay(for: selectedDate)
        let time = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
        fullDate = Calendar.current.date(byAdding: time, to: date) ?? fullDate
    }
    
    
    func delete() async {
        if let amt = amount, let id = transactionId{
            await bankAccountService.changeBalance(amount: amt, add: false)
            await transactionService.deleteTransaction(id: id)
        }
    }
    
    func save() async -> Bool {
        if isEditing {
            await bankAccountService.changeBalance(amount: (prevAmount ?? 0.0) - (amount ?? 0.0), add: false)
            await transactionService.editTransaction(id: transactionId ?? 0, category: selectedCategory?.id, amount: amount, transactionDate: fullDate, comment: description)
            return true
        } else {
            guard let amount = amount, let selectedCategory = selectedCategory else {
                isShowingAlert = true
                return false
            }
            let account = await bankAccountService.getAccount().id
            let id = transactionService.getId()
            await bankAccountService.changeBalance(amount: amount, add: true)
            await transactionService.addTransaction(transaction: Transaction(id: id, account: account, category: selectedCategory.id, amount: amount, transactionDate: fullDate, comment: description, createdAt: Date(), updatedAt: Date()))
            return true
        }
    }
}
