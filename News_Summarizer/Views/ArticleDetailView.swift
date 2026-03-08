import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    @StateObject private var viewModel = ArticleDetailViewModel()
    @Environment(\.openURL) private var openURL
    @State private var showOfflineReader = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                heroImage

                VStack(alignment: .leading, spacing: 10) {
                    Text(article.title)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)

                    HStack(spacing: 8) {
                        Text(article.sourceName ?? "Tech News")
                        Text("•")
                        if let date = article.publishedAt {
                            Text(date, style: .date)
                        } else {
                            Text("Today")
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    if let description = article.description, !description.isEmpty {
                        Text(description)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .textSelection(.enabled)
                    }
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    Button {
                        Task { await viewModel.magicSummarize(article: article) }
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                            Text(viewModel.isSummarizing ? "Summarizing…" : "Magic Summarize")
                            Spacer()
                            if viewModel.isSummarizing {
                                ProgressView()
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isSummarizing)

                    if let error = viewModel.errorMessage, !error.isEmpty {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if let summary = viewModel.summary, !summary.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("AI Summary")
                                .font(.headline)

                            Text(summary)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .textSelection(.enabled)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.secondary.opacity(0.10))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(.secondary.opacity(0.12), lineWidth: 1)
                        )
                        .padding(.top, 4)
                        .padding(.horizontal)
                        .transition(.opacity)
                    }

                    if viewModel.isDownloaded, viewModel.downloadedHTML != nil {
                        Button {
                            showOfflineReader = true
                        } label: {
                            Label("Read offline", systemImage: "tray.and.arrow.down.fill")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.bordered)
                    }

                    Button {
                        openURL(article.url)
                    } label: {
                        Label("Open full article", systemImage: "safari")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                .animation(.easeInOut(duration: 0.25), value: viewModel.summary)

                Spacer(minLength: 24)
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.toggleBookmark(article: article) }
                } label: {
                    Image(systemName: viewModel.isBookmarked ? "bookmark.fill" : "bookmark")
                }
                .accessibilityLabel(viewModel.isBookmarked ? "Remove bookmark" : "Bookmark")

                Button {
                    Task { await viewModel.downloadForOffline(article: article) }
                } label: {
                    Image(systemName: viewModel.isDownloaded ? "arrow.down.circle.fill" : "arrow.down.circle")
                }
                .disabled(viewModel.isDownloading)
                .accessibilityLabel(viewModel.isDownloaded ? "Downloaded" : "Download for offline")
            }
        }
        .task { await viewModel.syncSavedState(for: article) }
        .sheet(isPresented: $showOfflineReader) {
            NavigationStack {
                OfflineArticleView(title: article.title, html: viewModel.downloadedHTML ?? "")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showOfflineReader = false }
                        }
                    }
            }
        }
    }

    private var heroImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
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
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "newspaper.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.secondary.opacity(0.12), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        ArticleDetailView(
            article: Article(
                id: UUID(),
                title: "Sample Article Title",
                description: "This is a sample description that would come from NewsAPI.",
                url: URL(string: "https://example.com")!,
                imageURL: nil,
                sourceName: "Example",
                publishedAt: Date()
            )
        )
    }
}

