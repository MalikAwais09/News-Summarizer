import Foundation
#if canImport(GoogleGenerativeAI)
import GoogleGenerativeAI
#endif

protocol GeminiServiceProtocol {
    func summarize(title: String, description: String?) async throws -> String
}

/// Gemini summarization service.
///
/// Requires adding the Swift Package that provides the `GoogleGenerativeAI` module.
struct GeminiService: GeminiServiceProtocol {
    enum GeminiServiceError: LocalizedError {
        case sdkNotInstalled
        case missingAPIKey
        case emptyResponse

        var errorDescription: String? {
            switch self {
            case .sdkNotInstalled:
                return "GoogleGenerativeAI SDK not installed. Add the Swift Package dependency first."
            case .missingAPIKey:
                return "Missing Gemini API key. Add it in GeminiAPIKey.swift."
            case .emptyResponse:
                return "Gemini returned an empty response."
            }
        }
    }

    private let apiKey: String

    init(apiKey: String = GeminiAPIKey.value) {
        self.apiKey = apiKey
    }

    func summarize(title: String, description: String?) async throws -> String {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw GeminiServiceError.missingAPIKey
        }

        #if !canImport(GoogleGenerativeAI)
        throw GeminiServiceError.sdkNotInstalled
        #else

        // Use a model that your key actually exposes (from ListModels).
        // From your latest ListModels response, `gemini-2.5-flash` supports generateContent.
        let model = GenerativeModel(name: "gemini-2.5-flash", apiKey: apiKey)

        let prompt = """
        Summarize the following news article in exactly 3 sentences.
        Keep it clear and beginner-friendly. No bullet points.

        Title: \(title)
        Description: \(description ?? "N/A")
        """

        let response = try await model.generateContent(prompt)
        let text = response.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !text.isEmpty else { throw GeminiServiceError.emptyResponse }
        return text
        #endif
    }
}

