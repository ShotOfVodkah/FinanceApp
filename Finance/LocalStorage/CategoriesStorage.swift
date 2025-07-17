//
//  CategoriesStorage.swift
//  Finance
//
//  Created by Stepan Polyakov on 17.07.2025.
//

import SwiftData
import Foundation

@MainActor
final class SwiftDataCategoriesStorage: CategoriesStorageProtocol {
    private let modelContext: ModelContext
    
    init(container: ModelContainer) {
        self.modelContext = ModelContext(container)
    }
    
    func getAllCategories() async throws -> [Category] {
        let descriptor = FetchDescriptor<CategoryStorage>()
        let categories = try modelContext.fetch(descriptor)
        return categories.map { $0.toCategory() }
    }
    
    func getCategories(by direction: Direction) async throws -> [Category] {
        let isIncome = direction == .income
        let predicate = #Predicate<CategoryStorage> { $0.isIncome == isIncome }
        let descriptor = FetchDescriptor<CategoryStorage>(predicate: predicate)
        let categories = try modelContext.fetch(descriptor)
        return categories.map { $0.toCategory() }
    }
    
    func saveCategories(_ categories: [Category]) async throws {
        print("cохраняю")
        let descriptor = FetchDescriptor<CategoryStorage>()
        try modelContext.fetch(descriptor).forEach { modelContext.delete($0) }
        categories.forEach { category in
            modelContext.insert(CategoryStorage(from: category))
        }
        
        try modelContext.save()
    }
}
