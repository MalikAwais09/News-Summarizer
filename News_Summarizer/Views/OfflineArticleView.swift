import SwiftUI
import WebKit

struct OfflineArticleView: View {
    let title: String
    let html: String

    var body: some View {
        VStack(spacing: 0) {
            WebView(html: html)
                .ignoresSafeArea(edges: .bottom)
        }
        .navigationTitle("Offline")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct WebView: UIViewRepresentable {
    let html: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        webView.isOpaque = false
        webView.backgroundColor = UIColor.systemBackground
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(html, baseURL: nil)
    }
}

#Preview {
    NavigationStack {
        OfflineArticleView(title: "Sample", html: "<html><body><h1>Offline</h1><p>Hello</p></body></html>")
    }
}

