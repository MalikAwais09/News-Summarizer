import SwiftUI

struct BookmarksView: View {
    @State private var bookmarks: [SavedArticle] = []
    @State private var errorMessage: String?

    var body: some View {
        List {
            if let errorMessage, !errorMessage.isEmpty {
                Section {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                ForEach(bookmarks) { saved in
                    NavigationLink(value: saved) {
                        HStack(spacing: 12) {
                            thumbnail(saved.imageURL)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(saved.title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                    .lineLimit(3)

                                HStack(spacing: 6) {
                                    Text(saved.sourceName ?? "Saved")
                                    Text("•")
                                    if saved.downloadedHTML != nil {
                                        Text("Offline")
                                            .fontWeight(.semibold)
                                    } else {
                                        Text(saved.savedAt, style: .relative)
                                    }
                                }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Bookmarks")
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        do {
            errorMessage = nil
            bookmarks = try await ArticleStore.shared.fetchBookmarks()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func thumbnail(_ url: URL?) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.secondary.opacity(0.12))

            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        Image(systemName: "bookmark.fill")
                            .foregroundStyle(.secondary)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "bookmark.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 54, height: 54)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        BookmarksView()
    }
}

