import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var articles: [Article] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let newsService: NewsServiceProtocol

    init(newsService: NewsServiceProtocol = NewsService()) {
        self.newsService = newsService
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            articles = try await newsService.fetchLatestTechNews()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func refresh() async {
        await load()
    }
}

