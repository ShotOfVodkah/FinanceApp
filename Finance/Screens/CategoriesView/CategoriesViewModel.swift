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
    @Published var isLoading: Bool = false
    @Published var error: String?

    private var allCategories: [(String, Character)] = []

    init(categoriesService: CategoriesService) {
        self.categoriesService = categoriesService
    }

    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let all = try await categoriesService.getAll()
            self.allCategories = all.map { ($0.name, $0.emoji) }
            applySearch()
        } catch is CancellationError {
            print("Вышел с экрана, задача отменилась")
        } catch {
            self.error = error.localizedDescription
        }
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


