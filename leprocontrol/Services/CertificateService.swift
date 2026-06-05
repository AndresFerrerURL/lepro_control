import Foundation
import Security

struct LeproCertificateBundle {
    let rootCertificatePEM: Data
    let clientCertificatePEM: Data
    let privateKeyPEM: Data
}

final class CertificateService {
    func bundledPrivateKey() throws -> Data {
        guard let url = Bundle.main.url(forResource: "client_key", withExtension: "pem") else {
            throw LeproError.invalidResponse("Missing bundled client_key.pem resource")
        }
        return try Data(contentsOf: url)
    }
}

enum PEMParser {
    static func derData(from pemData: Data, label: String) throws -> Data {
        guard let pem = String(data: pemData, encoding: .utf8) else {
            throw LeproError.invalidResponse("Invalid PEM encoding for \(label)")
        }

        let lines = pem
            .components(separatedBy: .newlines)
            .filter { !$0.hasPrefix("-----BEGIN") && !$0.hasPrefix("-----END") && !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let base64 = lines.joined()

        guard let der = Data(base64Encoded: base64) else {
            throw LeproError.invalidResponse("Could not decode PEM body for \(label)")
        }
        return der
    }
}

enum MTLSIdentityBuilder {
    static func makeIdentity(clientCertificatePEM: Data, privateKeyPEM: Data) throws -> SecIdentity {
        let p12Data = try makePKCS12(clientCertificatePEM: clientCertificatePEM, privateKeyPEM: privateKeyPEM)
        let passphrase = pkcs12Passphrase
        let options = [kSecImportExportPassphrase as String: passphrase]

        var importedItems: CFArray?
        let status = SecPKCS12Import(p12Data as CFData, options as CFDictionary, &importedItems)
        guard status == errSecSuccess, let items = importedItems as? [[String: Any]], let first = items.first else {
            throw LeproError.invalidResponse("Could not import Lepro MQTT PKCS#12 identity: \(status)")
        }

        guard let identity = first[kSecImportItemIdentity as String] as! SecIdentity? else {
            throw LeproError.invalidResponse("Lepro MQTT PKCS#12 did not contain a SecIdentity")
        }

        return identity
    }

    static func makeRootCertificate(rootCertificatePEM: Data) throws -> SecCertificate {
        let rootDER = try PEMParser.derData(from: rootCertificatePEM, label: "root certificate")
        guard let rootCertificate = SecCertificateCreateWithData(nil, rootDER as CFData) else {
            throw LeproError.invalidResponse("Could not create SecCertificate from Lepro root certificate")
        }
        return rootCertificate
    }

    private static let pkcs12Passphrase = "leprocontrol-temporary-p12"

    private static func makePKCS12(clientCertificatePEM: Data, privateKeyPEM: Data) throws -> Data {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
            .appendingPathComponent("leprocontrol-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? fileManager.removeItem(at: directory)
        }

        let certURL = directory.appendingPathComponent("client_cert.pem")
        let keyURL = directory.appendingPathComponent("client_key.pem")
        let p12URL = directory.appendingPathComponent("identity.p12")

        try clientCertificatePEM.write(to: certURL, options: .atomic)
        try privateKeyPEM.write(to: keyURL, options: .atomic)

        let openssl = try findOpenSSL()
        let process = Process()
        process.executableURL = openssl
        process.arguments = [
            "pkcs12",
            "-export",
            "-inkey", keyURL.path,
            "-in", certURL.path,
            "-out", p12URL.path,
            "-passout", "pass:\(pkcs12Passphrase)",
            "-name", "leprocontrol"
        ]

        let errorPipe = Pipe()
        process.standardError = errorPipe
        process.standardOutput = Pipe()

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorText = String(data: errorData, encoding: .utf8) ?? "unknown OpenSSL error"
            throw LeproError.invalidResponse("OpenSSL could not create MQTT PKCS#12: \(errorText)")
        }

        return try Data(contentsOf: p12URL)
    }

    private static func findOpenSSL() throws -> URL {
        let candidates = [
            "/usr/bin/openssl",
            "/opt/homebrew/bin/openssl",
            "/usr/local/bin/openssl"
        ]

        for path in candidates where FileManager.default.isExecutableFile(atPath: path) {
            return URL(fileURLWithPath: path)
        }

        throw LeproError.invalidResponse("OpenSSL was not found. Needed to build the MQTT client identity from PEM files.")
    }
}
