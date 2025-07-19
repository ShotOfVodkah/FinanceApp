//
//  EditDeleteView.swift
//  Finance
//
//  Created by Stepan Polyakov on 09.07.2025.
//

import SwiftUI

struct EditDeleteView: View {
    @StateObject private var viewModel: EditDeleteViewModel
    @Environment(\.dismiss) private var dismiss

    init(transactionsService: TransactionsService, categoriesService: CategoriesService, direction: Direction, bankAccountService: BankAccountsService, selectedTransaction: (Transaction, Category)? = nil) {
        _viewModel = StateObject(wrappedValue: EditDeleteViewModel(transactionService: transactionsService, categoriesService: categoriesService, direction: direction, bankAccountService: bankAccountService, selectedTransaction: selectedTransaction))
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
                        List {
                            Section {
                                categoryPicker
                                amountPicker
                                datePicker
                                timePicker
                                descriptionPicker
                            }

                            if viewModel.isEditing {
                                Section {
                                    deleteButton
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                    }
                }
                .transition(.opacity)
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
            .navigationTitle(viewModel.directionText)
            .navigationBarBackButtonHidden(true)
            .toolbar(content: toolbarContent)
            .task {
                await viewModel.load()
            }
            .confirmationDialog(
                "Выберите категорию",
                isPresented: $viewModel.isChoosingCategory,
                titleVisibility: .visible,
                actions: confirmationDialogContent
            )
            .alert("Ошибка", isPresented: .constant(viewModel.error != nil)) {
                Button("Ок", role: .cancel) {
                    viewModel.error = nil
                }
            } message: {
                Text(viewModel.error ?? "Неизвестная ошибка")
            }
            .alert("Не все необходимые поля заполнены 💋", isPresented: $viewModel.isShowingAlert) {
                Button("OK", role: .cancel) { }
            }
        }
    }

    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Отмена") {
                dismiss()
            }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Button(viewModel.buttonText) {
                Task {
                    let success = await viewModel.save()
                    if success {
                        NotificationCenter.default.post(name: .transactionDidChange, object: nil)
                        dismiss()
                    }
                }
            }
        }
    }

    private func confirmationDialogContent() -> some View {
        ForEach(viewModel.categories, id: \.id) { category in
            Button {
                viewModel.selectedCategory = category
            } label: {
                HStack {
                    Text("\(category.emoji)  \(category.name)")
                }
            }
        }
    }

    private var categoryPicker: some View {
        Button {
            viewModel.isChoosingCategory.toggle()
        } label: {
            HStack {
                Text("Статья")
                Spacer()
                Text(viewModel.selectedCategory?.name ?? "Не выбрано")
                Image(systemName: "chevron.right")
                    .foregroundStyle(.gray)
            }
        }
        .buttonStyle(.plain)
    }

    private var amountPicker: some View {
        HStack {
            Text("Сумма")
            Spacer()
            TextField("0.00", text: $viewModel.amountText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .onChange(of: viewModel.amountText) { newValue in
                    viewModel.checkInput(num: newValue)
                }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    private var datePicker: some View {
        DatePicker("Дата", selection: $viewModel.selectedDate, in: ...Date(), displayedComponents: .date)
            .onChange(of: viewModel.selectedDate) {
                viewModel.updateDate()
            }
    }

    private var timePicker: some View {
        DatePicker("Время", selection: $viewModel.selectedTime, in: ...Date(), displayedComponents: .hourAndMinute)
            .onChange(of: viewModel.selectedTime) {
                viewModel.updateTime()
            }
    }

    private var descriptionPicker: some View {
        TextField("Комментарий", text: $viewModel.description)
    }

    private var deleteButton: some View {
        Button {
            Task {
                await viewModel.delete()
                NotificationCenter.default.post(name: .transactionDidChange, object: nil)
                dismiss()
            }
        } label: {
            Text(viewModel.deleteText)
                .foregroundStyle(Color.red)
        }
    }
}

