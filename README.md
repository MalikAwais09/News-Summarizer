# News Summarizer 📰✨

A beautiful, native iOS application built with SwiftUI that aggregates the latest technology news and provides AI-powered, beginner-friendly article summaries using Google's Gemini SDK. 

Never get bogged down by long articles again! Read the essentials, save your favorites, and even download full HTML content for seamless offline reading.

---

## 🚀 Features

- **🌐 Live Tech News Feed:** Streams the latest global technology news directly from [NewsAPI](https://newsapi.org) using efficient caching and pagination parameters.
- **✨ Magic Summarization:** Integrates with `gemini-2.5-flash` via the `GoogleGenerativeAI` SDK. Tapping "Magic Summarize" generates a strict, concise, 3-sentence beginner-friendly summary of any complex article instantly.
- **💾 Offline Reading:** Downloads full article HTML content in the background, caching it securely in a local database for access anytime—even on airplane mode.
- **🔖 Bookmarking System:** Save your favorite articles to a dedicated Bookmarks view for easy retrieval later.
- **🎨 Modern Native UI:** Built beautifully with SwiftUI utilizing native `NavigationStack`, `List` styling, and system SF Symbols for a familiar Apple platform experience.

---

## 🛠️ Tech Stack & Architecture

This application is built using modern iOS development paradigms aiming for responsiveness and modularity.

- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI
- **Architecture:** MVVM (Model-View-ViewModel)
  - Clear separation of concerns between `Views` (e.g., `HomeView`, `ArticleDetailView`) and `ViewModels` (e.g., `HomeViewModel`, `ArticleDetailViewModel`).
- **Concurrency:** Swift Concurrency (`async`/`await`, `Task`, `actor`) for safe, non-blocking asynchronous operations.
- **Networking:** Native `URLSession` for lightweight network calls to NewsAPI and raw HTML downloads.
- **Local Storage:** SQLite3 (via C-API Integration). `ArticleStore` is an `actor` that thread-safely manages bookmarks and offline HTML caching using direct `sqlite3` API calls.
- **AI Integrations:** `GoogleGenerativeAI` Swift SDK.

---

## 🔄 Complete Application Workflow

Understanding how data traverses the application:

1. **Dashboard Initialization (`HomeView`)**
   - Upon launch, the `HomeViewModel` executes an async call to `NewsService`.
   - `NewsService` builds a request to `newsapi.org/v2/everything` filtered for "technology" and decodes the JSON response into local `Article` models.
2. **Article Navigation (`ArticleDetailView`)**
   - The user selects an `Article` from the feed, pushing `ArticleDetailView` onto the `NavigationStack`.
   - The view renders the title, hero image, and metadata instantly.
3. **Engaging with the Article**
   - **Magic Summarize:** Tapping the sparkle icon triggers `ArticleDetailViewModel.magicSummarize()`. This constructs a tailored prompt injected with the article's title/description and queries `GeminiService` (powered by `gemini-2.5-flash`), returning an animated, dynamic UI update with the summary.
   - **Download for Offline:** Tapping the download icon invokes `OfflineDownloader` to execute a raw GET request against the article's URL, yielding raw HTML. This payload is passed to the `ArticleStore` actor.
   - **Bookmarking:** Toggling the bookmark icon executes an `upsertBookmark` command directly into the local `articles.sqlite3` database via the `ArticleStore`.
4. **Offline Viewing (`OfflineArticleView`)**
   - If an article is cached, the user can select "Read offline." This presents a modal sheet that elegantly forces rendering of the local HTML block native to the device.
5. **Saved Articles Retrieval (`BookmarksView`)**
   - Accessible from the dashboard, this view queries `ArticleStore.shared.fetchBookmarks()` or `fetchDownloaded()` utilizing standard SQLite queries (`SELECT ... WHERE bookmarked = 1`) to instantly rebuild the user's saved reading list.

---

## ⚙️ Prerequisites

- **Deployment Target:** iOS 16.0+
- **IDE:** Xcode 15.0+
- **NewsAPI Key** (Get yours from [NewsAPI.org](https://newsapi.org/))
- **Google Gemini API Key** (Get yours from [Google AI Studio](https://aistudio.google.com/app/apikey))

---

## 🏎️ Getting Started

Follow these steps to run the application locally:

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/News_Summarizer.git
   cd News_Summarizer
   ```

2. **Open the project in Xcode:**
   Double-click the `News_Summarizer.xcodeproj` file to open it in Xcode.

3. **Configure API Keys:**
   You must provide your own API keys for the app to function. Update the corresponding service files:
   
   - File: `News_Summarizer/Services/NewsAPIKey.swift`
     ```swift
     struct NewsAPIKey {
         static let value = "YOUR_NEWSAPI_KEY_HERE"
     }
     ```
   - File: `News_Summarizer/Services/GeminiAPIKey.swift`
     ```swift
     struct GeminiAPIKey {
         static let value = "YOUR_GEMINI_KEY_HERE"
     }
     ```

4. **Resolve Dependencies:**
   - The app actively depends on the **GoogleGenerativeAI** module. Ensure Xcode successfully resolves this Swift Package. You can trigger it manually via `File > Packages > Resolve Package Versions...`.

5. **Build and Run:**
   - Select your preferred iOS Simulator or connect a real device.
   - Hit **Run** (`Cmd + R`) to compile, build, and launch the app experience!

---

## 📜 License

This project is open-source and available under the MIT License.

## 📱 App Screenshots

<p align="center">
  <img src="https://github.com/MalikAwais09/News-Summarizer/blob/main/Screen%20Shots/Screens%20Image.png" />
</p>
