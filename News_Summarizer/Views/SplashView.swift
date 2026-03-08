import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(.systemIndigo),
                    Color(.systemPurple),
                    Color(.systemBlue)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.white.opacity(0.16))
                        .frame(width: 120, height: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(.white.opacity(0.18), lineWidth: 1)
                        )

                    Image(systemName: "newspaper.fill")
                        .font(.system(size: 54, weight: .semibold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.15), radius: 10, y: 8)
                }

                VStack(spacing: 8) {
                    Text("News Summarizer")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.white)

                    Text("Latest tech news, beautifully summarized\nand saved for offline reading.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.9))
                }

                HStack(spacing: 12) {
                    labelChip(icon: "sparkles", text: "AI Summaries")
                    labelChip(icon: "bookmark.fill", text: "Bookmarks")
                    labelChip(icon: "arrow.down.circle.fill", text: "Offline")
                }
                .padding(.top, 6)

                Spacer().frame(height: 10)

                ProgressView()
                    .tint(.white)
            }
            .padding(.horizontal, 24)
        }
    }

    private func labelChip(icon: String, text: String) -> some View {
        Label(text, systemImage: icon)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(.white.opacity(0.16))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.18), lineWidth: 1))
    }
}

#Preview {
    SplashView()
}

