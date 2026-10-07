import AuthenticationKit
import SwiftUI

@MainActor
struct AuthenticationRootView: View {
    @ObservedObject var environment: AppEnvironment

    @State
    private var session: Session?

    @State
    private var path: [AuthenticationRoute] = []

    @State
    private var didRestoreSession = false

    var body: some View {
        Group {
            if !didRestoreSession {
                ProgressView()
            } else if session != nil {
                ContentView(
                    environment: environment
                )
            } else {
                authenticationFlow
            }
        }
        .task {
            restoreSessionIfNeeded()
        }
    }

    private func restoreSessionIfNeeded() {
        guard !didRestoreSession else {
            return
        }

        defer {
            didRestoreSession = true
        }

        do {
            try AuthenticationService.shared
                .restoreSession()
            session =
                AuthenticationService.shared
                    .currentSession
        } catch {
            session = nil
        }
    }

    private var authenticationFlow: some View {
        NavigationStack(path: $path) {
            LoginView(
                onLoginSuccess: handleAuthenticationSuccess,
                onSignUp: {
                    path.append(.signUp)
                },
                onForgotPassword: {
                    path.append(.forgotPassword)
                }
            )
            .navigationDestination(
                for: AuthenticationRoute.self
            ) { route in
                switch route {
                case .signUp:
                    SignUpView(
                        onSignUpSuccess:
                            handleAuthenticationSuccess
                    )
                    .navigationTitle(AppL10n.string("auth.sign_up.title"))
                    .navigationBarTitleDisplayMode(.inline)

                case .forgotPassword:
                    ForgotPasswordView(
                        onForgotPasswordSuccess: {
                            path.removeAll()
                        }
                    )
                    .navigationTitle(AppL10n.string("auth.forgot_password.title"))
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }

    private func handleAuthenticationSuccess(
        _ session: Session
    ) {
        self.session = session
        path.removeAll()
    }
}

private enum AuthenticationRoute: Hashable {
    case signUp
    case forgotPassword
}
