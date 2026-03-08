import Foundation
import SQLite3

/// Minimal SQLite-backed store for bookmarks + offline downloads.
actor ArticleStore {
    static let shared = ArticleStore()
    let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    enum StoreError: LocalizedError {
        case openFailed
        case prepareFailed
        case stepFailed

        var errorDescription: String? {
            switch self {
            case .openFailed: return "Couldn’t open the local database."
            case .prepareFailed: return "Couldn’t prepare a database query."
            case .stepFailed: return "Couldn’t save data locally."
            }
        }
    }

    private var db: OpaquePointer?

    private init() { }

    deinit {
        if let db { sqlite3_close(db) }
    }

    // MARK: - Public API

    func isBookmarked(url: URL) throws -> Bool {
        try openIfNeeded()
        let sql = "SELECT bookmarked FROM saved_articles WHERE url = ? LIMIT 1;"
        let stmt = try prepare(sql)
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, url.absoluteString, -1, SQLITE_TRANSIENT)

        if sqlite3_step(stmt) == SQLITE_ROW {
            return sqlite3_column_int(stmt, 0) == 1
        }
        return false
    }

    func isDownloaded(url: URL) throws -> Bool {
        try openIfNeeded()
        let sql = "SELECT downloaded_html FROM saved_articles WHERE url = ? LIMIT 1;"
        let stmt = try prepare(sql)
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, url.absoluteString, -1, SQLITE_TRANSIENT)
        if sqlite3_step(stmt) == SQLITE_ROW {
            return sqlite3_column_text(stmt, 0) != nil
        }
        return false
    }

    func upsertBookmark(article: Article, bookmarked: Bool) throws {
        try openIfNeeded()

        // Ensure URL and title are valid
        guard !article.url.absoluteString.isEmpty else {
            print("Error: Article URL is empty")
            throw StoreError.stepFailed
        }
        let title = article.title.isEmpty ? "(No Title)" : article.title

        let sql = """
        INSERT INTO saved_articles
            (url, title, description, image_url, source_name, published_at, bookmarked, downloaded_html, saved_at)
        VALUES
            (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(url) DO UPDATE SET
            title = excluded.title,
            description = excluded.description,
            image_url = excluded.image_url,
            source_name = excluded.source_name,
            published_at = excluded.published_at,
            bookmarked = excluded.bookmarked,
            saved_at = excluded.saved_at;
        """

        let stmt = try prepare(sql)
        defer { sqlite3_finalize(stmt) }

        bindArticle(stmt: stmt, article: article, bookmarked: bookmarked, downloadedHTML: nil, savedAt: Date(), safeTitle: title)

        let result = sqlite3_step(stmt)
        if result != SQLITE_DONE {
            if let db = db, let errmsg = sqlite3_errmsg(db) {
                print("SQLite step failed with code \(result): \(String(cString: errmsg))")
            }
            throw StoreError.stepFailed
        } else {
            print("Article bookmarked successfully:", article.title)
        }
    }

    func saveDownload(article: Article, html: String) throws {
        try openIfNeeded()

        let sql = """
        INSERT INTO saved_articles
            (url, title, description, image_url, source_name, published_at, bookmarked, downloaded_html, saved_at)
        VALUES
            (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(url) DO UPDATE SET
            title = excluded.title,
            description = excluded.description,
            image_url = excluded.image_url,
            source_name = excluded.source_name,
            published_at = excluded.published_at,
            downloaded_html = excluded.downloaded_html,
            saved_at = excluded.saved_at;
        """

        let stmt = try prepare(sql)
        defer { sqlite3_finalize(stmt) }

        let safeTitle = article.title.isEmpty ? "(No Title)" : article.title
        bindArticle(stmt: stmt, article: article, bookmarked: false, downloadedHTML: html, savedAt: Date(), safeTitle: safeTitle)

        let result = sqlite3_step(stmt)
        if result != SQLITE_DONE {
            if let db = db, let errmsg = sqlite3_errmsg(db) {
                print("SQLite step failed with code \(result): \(String(cString: errmsg))")
            }
            throw StoreError.stepFailed
        } else {
            print("Article download saved successfully:", article.title)
        }
    }

    func fetchBookmarks() throws -> [SavedArticle] {
        try openIfNeeded()

        let sql = """
        SELECT url, title, description, image_url, source_name, published_at, bookmarked, downloaded_html, saved_at
        FROM saved_articles
        WHERE bookmarked = 1
        ORDER BY saved_at DESC;
        """

        let stmt = try prepare(sql)
        defer { sqlite3_finalize(stmt) }

        return readSavedArticles(stmt: stmt)
    }

    func fetchDownloaded() throws -> [SavedArticle] {
        try openIfNeeded()

        let sql = """
        SELECT url, title, description, image_url, source_name, published_at, bookmarked, downloaded_html, saved_at
        FROM saved_articles
        WHERE downloaded_html IS NOT NULL
        ORDER BY saved_at DESC;
        """

        let stmt = try prepare(sql)
        defer { sqlite3_finalize(stmt) }

        return readSavedArticles(stmt: stmt)
    }

    func getDownloadedHTML(url: URL) throws -> String? {
        try openIfNeeded()
        let sql = "SELECT downloaded_html FROM saved_articles WHERE url = ? LIMIT 1;"
        let stmt = try prepare(sql)
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, url.absoluteString, -1, SQLITE_TRANSIENT)
        if sqlite3_step(stmt) == SQLITE_ROW, let cStr = sqlite3_column_text(stmt, 0) {
            return String(cString: cStr)
        }
        return nil
    }

    // MARK: - SQLite setup

    private func openIfNeeded() throws {
        if db != nil { return }

        let url = try databaseURL()
        var handle: OpaquePointer?
        guard sqlite3_open(url.path, &handle) == SQLITE_OK else {
            if let errmsg = sqlite3_errmsg(handle) {
                print("SQLite open failed:", String(cString: errmsg))
            }
            throw StoreError.openFailed
        }
        db = handle

        try createTables()
    }

    private func databaseURL() throws -> URL {
        let fm = FileManager.default
        let docs = try fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return docs.appendingPathComponent("articles.sqlite3")
    }

    private func createTables() throws {
        let sql = """
        CREATE TABLE IF NOT EXISTS saved_articles (
            url TEXT PRIMARY KEY NOT NULL,
            title TEXT NOT NULL,
            description TEXT,
            image_url TEXT,
            source_name TEXT,
            published_at REAL,
            bookmarked INTEGER NOT NULL DEFAULT 0,
            downloaded_html TEXT,
            saved_at REAL NOT NULL
        );
        """

        var err: UnsafeMutablePointer<Int8>?
        if sqlite3_exec(db, sql, nil, nil, &err) != SQLITE_OK {
            if let err = err {
                print("SQLite table creation failed:", String(cString: err))
            }
            throw StoreError.stepFailed
        } else {
            print("Table created or already exists")
        }
    }

    private func prepare(_ sql: String) throws -> OpaquePointer? {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            if let db = db, let errmsg = sqlite3_errmsg(db) {
                print("SQLite prepare failed:", String(cString: errmsg))
            }
            throw StoreError.prepareFailed
        }
        return stmt
    }

    private func bindArticle(
        stmt: OpaquePointer?,
        article: Article,
        bookmarked: Bool,
        downloadedHTML: String?,
        savedAt: Date,
        safeTitle: String
    ) {
        sqlite3_bind_text(stmt, 1, (article.url.absoluteString as NSString).utf8String, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2, (safeTitle as NSString).utf8String, -1, SQLITE_TRANSIENT)

        if let description = article.description {
            sqlite3_bind_text(stmt, 3, (description as NSString).utf8String, -1, SQLITE_TRANSIENT)
        } else { sqlite3_bind_null(stmt, 3) }

        if let image = article.imageURL?.absoluteString {
            sqlite3_bind_text(stmt, 4, (image as NSString).utf8String, -1, SQLITE_TRANSIENT)
        } else { sqlite3_bind_null(stmt, 4) }

        if let sourceName = article.sourceName {
            sqlite3_bind_text(stmt, 5, (sourceName as NSString).utf8String, -1, SQLITE_TRANSIENT)
        } else { sqlite3_bind_null(stmt, 5) }

        if let publishedAt = article.publishedAt {
            sqlite3_bind_double(stmt, 6, publishedAt.timeIntervalSince1970)
        } else { sqlite3_bind_null(stmt, 6) }

        sqlite3_bind_int(stmt, 7, bookmarked ? 1 : 0)

        if let downloadedHTML {
            sqlite3_bind_text(stmt, 8, (downloadedHTML as NSString).utf8String, -1, SQLITE_TRANSIENT)
        } else { sqlite3_bind_null(stmt, 8) }

        sqlite3_bind_double(stmt, 9, savedAt.timeIntervalSince1970)
    }

    private func readSavedArticles(stmt: OpaquePointer?) -> [SavedArticle] {
        var results: [SavedArticle] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let urlString = String(cString: sqlite3_column_text(stmt, 0))
            let title = String(cString: sqlite3_column_text(stmt, 1))

            let description = sqlite3_column_text(stmt, 2).flatMap { String(cString: $0) }
            let imageURLString = sqlite3_column_text(stmt, 3).flatMap { String(cString: $0) }
            let sourceName = sqlite3_column_text(stmt, 4).flatMap { String(cString: $0) }

            let publishedAt: Date?
            if sqlite3_column_type(stmt, 5) != SQLITE_NULL {
                publishedAt = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 5))
            } else { publishedAt = nil }

            let bookmarked = sqlite3_column_int(stmt, 6) == 1
            let downloadedHTML = sqlite3_column_text(stmt, 7).flatMap { String(cString: $0) }
            let savedAt = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 8))

            let url = URL(string: urlString) ?? URL(string: "https://example.com")!
            let imageURL = imageURLString.flatMap(URL.init(string:))

            results.append(
                SavedArticle(
                    id: urlString,
                    title: title,
                    description: description,
                    url: url,
                    imageURL: imageURL,
                    sourceName: sourceName,
                    publishedAt: publishedAt,
                    isBookmarked: bookmarked,
                    downloadedHTML: downloadedHTML,
                    savedAt: savedAt
                )
            )
        }
        return results
    }
}


