import Foundation

struct OfflineDownloader {
    enum DownloadError: LocalizedError {
        case invalidResponse
        case httpStatus(Int)
        case emptyContent

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Unexpected response while downloading."
            case .httpStatus(let code):
                return "Download failed (HTTP \(code))."
            case .emptyContent:
                return "Downloaded article was empty."
            }
        }
    }

    func downloadHTML(from url: URL) async throws -> String {
        var request = URLRequest(url: url)
        request.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 25

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw DownloadError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw DownloadError.httpStatus(http.statusCode) }

        let html = String(data: data, encoding: .utf8) ?? String(decoding: data, as: UTF8.self)
        let trimmed = html.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw DownloadError.emptyContent }
        return trimmed
    }
}

