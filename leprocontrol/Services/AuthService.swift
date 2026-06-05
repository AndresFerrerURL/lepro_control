import Foundation

final class AuthService {
    private let apiClient: LeproAPIClient

    init(apiClient: LeproAPIClient) {
        self.apiClient = apiClient
    }

    var savedSession: LeproSession? {
        apiClient.savedSession
    }

    func login(email: String, password: String, region: LeproRegion, language: String) async throws -> LeproSession {
        try await apiClient.login(email: email, password: password, region: region, language: language)
    }

    func logout() throws {
        try apiClient.logout()
    }
}
