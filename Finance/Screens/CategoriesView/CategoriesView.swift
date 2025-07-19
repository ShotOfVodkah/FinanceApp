//
//  CategoriesView.swift
//  Finance
//
//  Created by Stepan Polyakov on 27.06.2025.
//

import SwiftUI
struct CategoriesView: View {
    @StateObject private var viewModel: CategoriesViewModel

    init(categoriesService: CategoriesService) {
        _viewModel = StateObject(wrappedValue: CategoriesViewModel(categoriesService: categoriesService))
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
                            Section(header: Text("СТАТЬИ")) {
                                ForEach(viewModel.categories, id: \.0) { name, emoji in
                                    HStack {
                                        Text("\(emoji)")
                                            .padding(5)
                                            .background(Color.accentColor.opacity(0.2))
                                            .clipShape(Circle())
                                        Text(name)
                                    }
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                    }
                }
                .transition(.opacity)
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
            .navigationTitle("Мои статьи")
            .searchable(text: $viewModel.searchText, prompt: "Поиск")
            .onChange(of: viewModel.searchText) { _ in
                viewModel.applySearch()
            }
            .task {
                await viewModel.load()
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
}

