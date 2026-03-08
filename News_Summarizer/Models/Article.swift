import Foundation

struct Article: Identifiable, Hashable {
    let id: UUID
    let title: String
    let description: String?
    let url: URL
    let imageURL: URL?
    let sourceName: String?
    let publishedAt: Date?
}

