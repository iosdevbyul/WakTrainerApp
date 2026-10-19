import SwiftUI

/// Branded post-launch transition. The system launch screen uses the same image.
struct AppStartupSplash<Content: View>: View {
    @State private var showsSplash = true
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            content()

            if showsSplash {
                Color.black.ignoresSafeArea()
                    .overlay {
                        Image("TrisSplashLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 190, height: 190)
                            .accessibilityHidden(true)
                    }
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            try? await Task.sleep(for: .milliseconds(850))
            withAnimation(.easeOut(duration: 0.28)) {
                showsSplash = false
            }
        }
    }
}
