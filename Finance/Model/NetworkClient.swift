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
    case noInternet
    case hostNotFound
    case cancelled
    case unknown(Error)
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
        case .serverError(let code):
            return "Ошибка сервера (код \(code))."
        case .decodingError:
            return "Не удалось декодировать ответ сервера."
        case .encodingError:
            return "Не удалось закодировать данные запроса."
        case .noInternet:
            return "Отсутствует подключение к интернету."
        case .hostNotFound:
            return "Сервер не найден. Проверьте подключение."
        case .cancelled:
            return "Запрос был отменён."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

final class NetworkClient {
    private let baseURL: URL
    private let token: String

    init(baseURL: String, token: String) {
        guard let url = URL(string: baseURL) else {
            fatalError("Invalid base URL: \(baseURL)")
        }
        self.baseURL = url
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
        } catch let urlError as URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                throw NetworkError.noInternet
            case .cannotFindHost, .cannotConnectToHost:
                throw NetworkError.hostNotFound
            case .cancelled:
                throw NetworkError.cancelled
            default:
                throw NetworkError.unknown(urlError)
            }
        } catch {
            throw NetworkError.unknown(error)
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
            throw NetworkError.invalidResponse
        }

        // Пустой ответ (204)
        if httpResponse.statusCode == 204 {
            if T.self == EmptyResponse.self {
                return EmptyResponse() as! T
            } else {
                throw NetworkError.decodingError
            }
        }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                
                if let date = formatter.date(from: dateString) {
                    return date
                }
                
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Invalid date format: \(dateString)"
                )
            }
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Decoding error details: \(error)")
            throw NetworkError.decodingError
        }
    }
}
