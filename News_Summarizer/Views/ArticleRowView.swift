import SwiftUI

struct ArticleRowView: View {
    let article: Article

    var body: some View {
        HStack(spacing: 12) {
            thumbnail

            VStack(alignment: .leading, spacing: 6) {
                Text(article.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(3)

                HStack(spacing: 6) {
                    if let source = article.sourceName, !source.isEmpty {
                        Text(source)
                    } else {
                        Text("Tech News")
                    }

                    Text("•")

                    if let date = article.publishedAt {
                        Text(date, style: .relative)
                    } else {
                        Text("Just now")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var thumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.secondary.opacity(0.12))

            if let url = article.imageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Image(systemName: "newspaper.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "newspaper.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 74, height: 74)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.secondary.opacity(0.15), lineWidth: 1)
        )
    }
}

#Preview {
    ArticleRowView(
        article: Article(
            id: UUID(),
            title: "Apple announces new SwiftUI features for building modern apps",
            description: "A quick overview of what’s new.",
            url: URL(string: "https://example.com")!,
            imageURL: nil,
            sourceName: "Example",
            publishedAt: Date()
        )
    )
    .padding()
}

