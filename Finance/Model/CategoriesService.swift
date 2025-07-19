//
//  CategoriesService.swift
//  Finance
//
//  Created by Stepan Polyakov on 14.07.2025.
//

final class CategoriesService {
    private let networkClient: NetworkClient
    private let localStorage: CategoriesStorageProtocol
    
    init(networkClient: NetworkClient, localStorage: CategoriesStorageProtocol) {
        self.networkClient = networkClient
        self.localStorage = localStorage
    }
    
    func getAll() async throws -> [Category] {
        do {
            let response: [APICategory] = try await networkClient.request(
                method: "GET",
                path: "categories",
                responseType: [APICategory].self
            )
            
            let categories = response.map { apiCategory in
                Category(
                    id: apiCategory.id,
                    name: apiCategory.name,
                    emoji: apiCategory.emoji.first ?? "💋",
                    direction: apiCategory.isIncome ? .income : .outcome
                )
            }
            try await localStorage.saveCategories(categories)
            return categories
        } catch let error as NetworkError {
            if case .noInternet = error {
                return try await localStorage.getAllCategories()
            } else {
                throw error
            }
        }
    }
    
    func getSpecific(dir: Direction) async throws -> [Category] {
        do {
            let response: [APICategory] = try await networkClient.request(
                method: "GET",
                path: "categories/type/\(dir == .income ? true : false)",
                responseType: [APICategory].self
            )
            
            return response.map { apiCategory in
                Category(
                    id: apiCategory.id,
                    name: apiCategory.name,
                    emoji: apiCategory.emoji.first ?? "💋",
                    direction: apiCategory.isIncome ? .income : .outcome
                )
            }
        } catch let error as NetworkError {
            if case .noInternet = error {
                return try await localStorage.getCategories(by: dir)
            } else {
                throw error
            }
        }
    }
}

struct APICategory: Decodable {
    let id: Int
    let name: String
    let emoji: String
    let isIncome: Bool
}
