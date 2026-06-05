import Combine
import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var region: LeproRegion = .eu
    @Published var language = "en"
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var isAuthenticated = false
    @Published private(set) var session: LeproSession?

    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
        bootstrap()
    }

    func bootstrap() {
        guard let savedSession = authService.savedSession else {
            isAuthenticated = false
            return
        }
        session = savedSession
        email = savedSession.account
        region = savedSession.region
        language = savedSession.language
        isAuthenticated = true
    }

    func login() async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Introduce usuario y contraseña."
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            let newSession = try await authService.login(email: trimmedEmail, password: password, region: region, language: language)
            session = newSession
            isAuthenticated = true
            password = ""
        } catch let error as LeproError {
            print("Login error: \(error.localizedDescription)")
            errorMessage = error.userMessage
            isAuthenticated = false
        } catch {
            print("Login error: \(error)")
            errorMessage = LeproError.unknown(error.localizedDescription).userMessage
            isAuthenticated = false
        }
        isLoading = false
    }

    func logout() {
        do {
            try authService.logout()
        } catch {
            print("Logout error: \(error)")
        }
        session = nil
        isAuthenticated = false
        password = ""
    }
}
