import Combine
import Foundation
import SwiftUI

@MainActor
final class ArticleDetailViewModel: ObservableObject {
    @Published private(set) var summary: String?
    @Published private(set) var isSummarizing = false
    @Published var errorMessage: String?

    @Published private(set) var isBookmarked = false
    @Published private(set) var isDownloaded = false
    @Published private(set) var downloadedHTML: String?
    @Published private(set) var isDownloading = false

    private let geminiService: GeminiServiceProtocol

    init(geminiService: GeminiServiceProtocol = GeminiService()) {
        self.geminiService = geminiService
    }

    func syncSavedState(for article: Article) async {
        do {
            isBookmarked = try await ArticleStore.shared.isBookmarked(url: article.url)
            isDownloaded = try await ArticleStore.shared.isDownloaded(url: article.url)
            downloadedHTML = try await ArticleStore.shared.getDownloadedHTML(url: article.url)
        } catch {
            // Non-fatal: keep UI working even if DB fails
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func toggleBookmark(article: Article) async {
        do {
            let newValue = !isBookmarked
            try await ArticleStore.shared.upsertBookmark(article: article, bookmarked: newValue)
            withAnimation(.easeInOut(duration: 0.2)) {
                isBookmarked = newValue
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func downloadForOffline(article: Article) async {
        guard !isDownloading else { return }
        isDownloading = true
        errorMessage = nil
        defer { isDownloading = false }

        do {
            let html = try await OfflineDownloader().downloadHTML(from: article.url)
            try await ArticleStore.shared.saveDownload(article: article, html: html)
            withAnimation(.easeInOut(duration: 0.25)) {
                isDownloaded = true
                downloadedHTML = html
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func magicSummarize(article: Article) async {
        guard !isSummarizing else { return }
        isSummarizing = true
        errorMessage = nil
        defer { isSummarizing = false }

        do {
            let text = try await geminiService.summarize(title: article.title, description: article.description)
            withAnimation(.easeInOut(duration: 0.25)) {
                summary = text
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

