//
//  CategoriesService.swift
//  Finance
//
//  Created by Stepan Polyakov on 14.07.2025.
//

final class CategoriesService {
    private let networkClient: NetworkClient
    
    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
    
    func getAll() async throws -> [Category] {
        let response: [APICategory] = try await networkClient.request(
            method: "GET",
            path: "categories",
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
    }
    
    func getSpecific(dir: Direction) async throws -> [Category] {
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
    }
}

struct APICategory: Decodable {
    let id: Int
    let name: String
    let emoji: String
    let isIncome: Bool
}
