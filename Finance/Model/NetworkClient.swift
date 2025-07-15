//
//  NetworkClient.swift
//  Finance
//
//  Created by Stepan Polyakov on 14.07.2025.
//

import Foundation

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(code: Int)
    case decodingError
    case encodingError
    case unknownError
}

extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Неверный URL."
        case .invalidResponse:
            return "Некорректный ответ от сервера."
        case .unauthorized:
            return "Вы не авторизованы."
        case .serverError(_):
            return "Ошибка сервера."
        case .decodingError:
            return "Не удалось декодировать ответ сервера."
        case .encodingError:
            return "Не удалось закодировать данные запроса."
        case .unknownError:
            return "Неизвестная ошибка."
        }
    }
}


final class NetworkClient {
    private let baseURL: URL
    private let token: String
    
    init(baseURL: String, token: String) {
        self.baseURL = URL(string: baseURL)!
        self.token = token
    }
    
    func request<T: Decodable>(
        method: String,
        path: String,
        queryItems: [URLQueryItem]? = nil,
        body: Encodable? = nil,
        responseType: T.Type
    ) async throws -> T {
        var url = baseURL.appendingPathComponent(path)
        if let queryItems = queryItems {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = queryItems
            if let newURL = components?.url {
                url = newURL
            }
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = body {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                request.httpBody = try encoder.encode(body)
            } catch {
                throw NetworkError.encodingError
            }
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch {
            throw error
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200..<300:
            break
        case 401:
            throw NetworkError.unauthorized
        case 400..<500, 500..<600:
            throw NetworkError.serverError(code: httpResponse.statusCode)
        default:
            throw NetworkError.unknownError
        }

        if httpResponse.statusCode == 204 {
            if T.self == EmptyResponse.self {
                return EmptyResponse() as! T
            } else {
                throw NetworkError.decodingError
            }
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }

}
