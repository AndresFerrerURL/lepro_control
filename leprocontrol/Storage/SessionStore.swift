import Foundation

final class SessionStore {
    private let keychain: KeychainService
    private let account = "lepro-session"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(keychain: KeychainService = KeychainService()) {
        self.keychain = keychain
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func save(_ session: LeproSession) throws {
        let data = try encoder.encode(session)
        try keychain.save(data, account: account)
    }

    func load() throws -> LeproSession? {
        guard let data = try keychain.load(account: account) else {
            return nil
        }
        return try decoder.decode(LeproSession.self, from: data)
    }

    func clear() throws {
        try keychain.delete(account: account)
    }
}
