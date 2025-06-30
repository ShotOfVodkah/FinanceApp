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
            .navigationTitle("Мои статьи")
            .searchable(text: $viewModel.searchText, prompt: "Поиск")
            .onChange(of: viewModel.searchText) { _ in
                viewModel.applySearch()
            }
        }
        .listStyle(.insetGrouped)
        .task {
            await viewModel.load()
        }
        .background(Color(.systemGray6))
    }
}
