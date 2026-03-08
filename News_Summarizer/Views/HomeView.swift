import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.articles.isEmpty {
                    loadingState
                } else if let error = viewModel.errorMessage, viewModel.articles.isEmpty {
                    errorState(message: error)
                } else {
                    articlesList
                }
            }
            .navigationTitle("Tech News")
            .toolbarTitleDisplayMode(.large)
            .toolbar {
                NavigationLink {
                    BookmarksView()
                } label: {
                    Image(systemName: "bookmark")
                }
                .accessibilityLabel("Bookmarks")
            }
            .task { await viewModel.load() }
            .refreshable { await viewModel.refresh() }
        }
    }

    private var articlesList: some View {
       
            List {
                if let error = viewModel.errorMessage, !error.isEmpty {
                    Section {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section {
                    ForEach(viewModel.articles) { article in
                        NavigationLink(value: article) {
                            ArticleRowView(article: article)
                                .padding(.vertical, 6)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationDestination(for: Article.self) { article in
                ArticleDetailView(article: article)
            }
            .navigationDestination(for: SavedArticle.self) { saved in
                ArticleDetailView(
                    article: Article(
                        id: UUID(),
                        title: saved.title,
                        description: saved.description,
                        url: saved.url,
                        imageURL: saved.imageURL,
                        sourceName: saved.sourceName,
                        publishedAt: saved.publishedAt
                    )
                )
            }
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Fetching latest articles…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private func errorState(message: String) -> some View {
        ContentUnavailableView(
            "Can’t load news",
            systemImage: "wifi.exclamationmark",
            description: Text(message)
        )
        .padding()
    }
}

#Preview {
    HomeView()
}

