//
//  CategoriesViewModel.swift
//  Finance
//
//  Created by Stepan Polyakov on 27.06.2025.
//

import Foundation

@MainActor
final class CategoriesViewModel: ObservableObject {
    private let categoriesService: CategoriesService
    
    @Published var categories: [(String, Character)] = []
    @Published var searchText: String = ""
    
    private var allCategories: [(String, Character)] = []
    
    init(categoriesService: CategoriesService) {
        self.categoriesService = categoriesService
    }
    
    func load() async {
        categories = []
        allCategories = await categoriesService.getAll().map { ($0.name, $0.emoji) }
        applySearch()
    }
    
    func applySearch() {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            categories = allCategories
        } else {
            categories = allCategories.filter { name, _ in
                searchText.isSubsequence(of: name)
            }
        }
    }
}

