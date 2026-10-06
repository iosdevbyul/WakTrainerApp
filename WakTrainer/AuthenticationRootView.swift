import AuthenticationKit
import SwiftUI

@MainActor
struct AuthenticationRootView: View {
    @ObservedObject var environment: AppEnvironment

    @State
    private var session: Session?

    @State
    private var path: [AuthenticationRoute] = []

    var body: some View {
        Group {
            if session != nil {
                ContentView(
                    environment: environment
                )
            } else {
                authenticationFlow
            }
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
                    .navigationTitle("회원가입")
                    .navigationBarTitleDisplayMode(.inline)

                case .forgotPassword:
                    ForgotPasswordView(
                        onForgotPasswordSuccess: {
                            path.removeAll()
                        }
                    )
                    .navigationTitle("비밀번호 찾기")
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
