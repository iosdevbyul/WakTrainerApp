import AuthenticationKit
import SwiftUI
import WakTrainerDesignSystem

@MainActor
struct AuthenticationRootView: View {
    @ObservedObject var environment: AppEnvironment

    private let authenticationService: AuthenticationService

    @State
    private var session: Session?

    @State
    private var isRestoringSession = true

    @State
    private var path: [AuthenticationRoute] = []

    init(
        environment: AppEnvironment,
        authenticationService: AuthenticationService = .shared
    ) {
        self.environment = environment
        self.authenticationService = authenticationService
    }

    var body: some View {
        Group {
            if isRestoringSession {
                ProgressView()
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
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

    private var authenticationFlow: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                VStack(spacing: 14) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(WakColor.primary)
                        .frame(width: 84, height: 84)
                        .background(WakColor.primary.opacity(0.15), in: RoundedRectangle(cornerRadius: 22))

                    Text("WakTrainer")
                        .font(WakTypography.screenTitle)
                        .foregroundStyle(WakColor.textPrimary)

                    Text(AppL10n.string("auth.welcome.description"))
                        .font(WakTypography.body)
                        .foregroundStyle(WakColor.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)

                LoginView(
                    theme: .wakTrainer,
                    onLoginSuccess: handleAuthenticationSuccess,
                    onSignUp: { path.append(.signUp) },
                    onForgotPassword: { path.append(.forgotPassword) }
                )
            }
            .background(WakColor.background.ignoresSafeArea())
            .navigationDestination(
                for: AuthenticationRoute.self
            ) { route in
                switch route {
                case .signUp:
                    SignUpView(
                        onSignUpSuccess:
                            handleAuthenticationSuccess
                    )
                    .navigationTitle(
                        AppL10n.string(
                            "auth.sign_up.title"
                        )
                    )
                    .navigationBarTitleDisplayMode(.inline)

                case .forgotPassword:
                    ForgotPasswordView(
                        onForgotPasswordSuccess: {
                            path.removeAll()
                        }
                    )
                    .navigationTitle(
                        AppL10n.string(
                            "auth.forgot_password.title"
                        )
                    )
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(WakColor.primary)
    }

    private func restoreSessionIfNeeded() {
        guard isRestoringSession else {
            return
        }

        defer {
            isRestoringSession = false
        }

        do {
            try authenticationService.restoreSession()
            session = authenticationService.currentSession
        } catch {
            session = nil
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

private extension AuthenticationTheme {
    static let wakTrainer = AuthenticationTheme(
        background: WakColor.background,
        primary: WakColor.primary,
        text: WakColor.textPrimary,
        secondaryText: WakColor.textSecondary,
        placeholder: WakColor.textSecondary,
        border: WakColor.divider,
        error: .red,
        link: WakColor.primary,
        button: .init(
            background: WakColor.primary,
            foreground: WakColor.background,
            disabled: WakColor.textSecondary.opacity(0.4)
        ),
        textField: .init(
            background: WakColor.surface,
            text: WakColor.textPrimary,
            placeholder: WakColor.textSecondary,
            border: WakColor.divider,
            focusedBorder: WakColor.primary
        )
    )
}
