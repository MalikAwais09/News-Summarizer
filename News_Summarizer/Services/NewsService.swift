import Foundation

protocol NewsServiceProtocol {
    func fetchLatestTechNews() async throws -> [Article]
}

struct NewsService: NewsServiceProtocol {
    enum NewsServiceError: LocalizedError {
        case missingAPIKey
        case invalidURL
        case invalidResponse
        case httpStatus(Int)
        case decodingFailed

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "Missing NewsAPI key. Add it in NewsAPIKey.swift."
            case .invalidURL:
                return "Couldn’t build the NewsAPI URL."
            case .invalidResponse:
                return "Unexpected response from server."
            case .httpStatus(let code):
                return "Request failed (HTTP \(code))."
            case .decodingFailed:
                return "Couldn’t read the news data."
            }
        }
    }

    private let apiKey: String
    private let urlSession: URLSession

    init(apiKey: String = NewsAPIKey.value, urlSession: URLSession = .shared) {
        self.apiKey = apiKey
        self.urlSession = urlSession
    }

    func fetchLatestTechNews() async throws -> [Article] {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NewsServiceError.missingAPIKey
        }

        // Using /v2/everything works globally without needing a country code.
        // It finds recent articles matching "technology".
        var components = URLComponents(string: "https://newsapi.org/v2/everything")
        components?.queryItems = [
            URLQueryItem(name: "q", value: "technology"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "sortBy", value: "publishedAt"),
            URLQueryItem(name: "pageSize", value: "30")
        ]

        guard let url = components?.url else { throw NewsServiceError.invalidURL }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")

        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw NewsServiceError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw NewsServiceError.httpStatus(http.statusCode) }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let decoded = try? decoder.decode(NewsAPIResponse.self, from: data) else {
            throw NewsServiceError.decodingFailed
        }

        return decoded.articles.compactMap { dto in
            guard
                let title = dto.title?.trimmingCharacters(in: .whitespacesAndNewlines),
                !title.isEmpty,
                let urlString = dto.url,
                let url = URL(string: urlString)
            else { return nil }

            return Article(
                id: UUID(),
                title: title,
                description: dto.description,
                url: url,
                imageURL: URL(string: dto.urlToImage ?? ""),
                sourceName: dto.source?.name,
                publishedAt: dto.publishedAt
            )
        }
    }
}

// MARK: - NewsAPI DTOs

private struct NewsAPIResponse: Decodable {
    let articles: [NewsAPIArticle]
}

private struct NewsAPIArticle: Decodable {
    struct Source: Decodable {
        let name: String?
    }

    let source: Source?
    let title: String?
    let description: String?
    let url: String?
    let urlToImage: String?
    let publishedAt: Date?
}

