import Foundation

/// Article stored locally (bookmarked and/or downloaded for offline reading).
struct SavedArticle: Identifiable, Hashable {
    /// Stable ID (we use the article URL string).
    let id: String

    let title: String
    let description: String?
    let url: URL
    let imageURL: URL?
    let sourceName: String?
    let publishedAt: Date?

    let isBookmarked: Bool
    let downloadedHTML: String?
    let savedAt: Date
}

extension SavedArticle {
    init(from article: Article, isBookmarked: Bool, downloadedHTML: String?, savedAt: Date = Date()) {
        self.id = article.url.absoluteString
        self.title = article.title
        self.description = article.description
        self.url = article.url
        self.imageURL = article.imageURL
        self.sourceName = article.sourceName
        self.publishedAt = article.publishedAt
        self.isBookmarked = isBookmarked
        self.downloadedHTML = downloadedHTML
        self.savedAt = savedAt
    }
}

