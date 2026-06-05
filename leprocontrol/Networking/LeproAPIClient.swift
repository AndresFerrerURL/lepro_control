import Foundation
import CryptoKit

final class LeproAPIClient {
    private static let defaultFCMToken = "dfi8s76mRTCxRxm3UtNp2z:APA91bHWMEWKT9CgNfGJ961jot2qgfYdWePbO5sQLovSFDI7U_H-ulJiqIAB2dpZUUrhzUNWR3OE_eM83i9IDLk1a5ZRwHDxMA_TnGqdpE8H-0_JML8pBFA"

    private let sessionStore: SessionStore
    private let certificateService: CertificateService
    private let urlSession: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let mqttClient = LeproMQTTClient()

    private var session: LeproSession?
    private var mqttInfo: MqttInfo?
    private var cachedDevices: [String: LeproDevice] = [:]
    private var mqttPrepared = false

    init(
        sessionStore: SessionStore = SessionStore(),
        certificateService: CertificateService = CertificateService(),
        urlSession: URLSession = {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 20
            config.timeoutIntervalForResource = 45
            return URLSession(configuration: config)
        }()
    ) {
        self.sessionStore = sessionStore
        self.certificateService = certificateService
        self.urlSession = urlSession
        self.session = try? sessionStore.load()
    }

    var savedSession: LeproSession? {
        session
    }

    func login(email: String, password: String, region: LeproRegion = .eu, language: String = "en") async throws -> LeproSession {
        let apiHost = region.apiHost
        let timestamp = LeproHeaderFactory.timestamp()
        let mac = LeproMACFactory.persistentMAC(for: email)
        let requestBody = LoginRequest(
            platform: LeproHeaderFactory.platform,
            account: email,
            password: password,
            mac: mac,
            timestamp: timestamp,
            language: language,
            // Mirrors lepro_led/light.py, which supplies this default when no fcm_token is configured.
            // TODO: Replace with a first-party registration flow if Lepro requires per-install FCM tokens.
            fcmToken: Self.defaultFCMToken
        )

        var request = URLRequest(url: URL(string: "https://\(apiHost)/user/login")!)
        request.httpMethod = "POST"
        request.httpBody = try encoder.encode(requestBody)
        request.allHTTPHeaderFields = LeproHeaderFactory.headers(apiHost: apiHost, language: language, timestamp: timestamp)

        let loginResponse: LoginResponse = try await send(request)
        guard loginResponse.code == 0 else {
            print("Lepro login failed: \(loginResponse.msg ?? "unknown error")")
            throw LeproError.invalidCredentials
        }
        guard let token = loginResponse.data?.token, !token.isEmpty else {
            throw LeproError.invalidResponse("Login response did not contain data.token")
        }

        let newSession = LeproSession(account: email, token: token, region: region, language: language, mac: mac, createdAt: Date())
        try sessionStore.save(newSession)
        session = newSession
        mqttPrepared = false
        cachedDevices = [:]
        return newSession
    }

    func logout() throws {
        mqttClient.disconnect()
        mqttPrepared = false
        cachedDevices = [:]
        mqttInfo = nil
        session = nil
        try sessionStore.clear()
    }

    func refreshSessionIfNeeded() async throws {
        if session == nil {
            session = try sessionStore.load()
        }
        guard session != nil else {
            throw LeproError.missingSession
        }
        // TODO: The Home Assistant integration does not expose a refresh-token endpoint.
        // If Lepro Cloud later returns refresh tokens, implement renewal here.
    }

    func fetchDevices() async throws -> [LeproDevice] {
        try await refreshSessionIfNeeded()
        let profile = try await fetchUserProfile()
        mqttInfo = profile.mqtt

        async let rootData = downloadCertificate(from: profile.mqtt.root)
        async let certData = downloadCertificate(from: profile.mqtt.cert)
        let bundle = LeproCertificateBundle(
            rootCertificatePEM: try await rootData,
            clientCertificatePEM: try await certData,
            privateKeyPEM: try certificateService.bundledPrivateKey()
        )

        let fid = try await fetchFirstFamilyId()
        let devices = try await fetchDevices(fid: fid)
        cachedDevices = Dictionary(uniqueKeysWithValues: devices.map { ($0.deviceId, $0) })

        do {
            try await prepareMQTTIfNeeded(bundle: bundle)
        } catch {
            print("MQTT setup failed after device list succeeded: \(error)")
        }
        return devices
    }

    func turnOn(deviceId: String) async throws {
        var payload: [String: LeproCommandValue] = ["d1": .int(1)]
        if let device = cachedDevices[deviceId], !isBModel(device), let d50 = device.d50 {
            payload["d2"] = .int(2)
            payload["d52"] = .int(LeproBrightness.homeAssistantToDevice(device.brightness255))
            payload["d50"] = .string(d50)
        }
        try await mqttClient.publishCommand(deviceId: deviceId, payload: payload)
        cachedDevices[deviceId]?.d1 = 1
        cachedDevices[deviceId]?.powerSwitch = 1
    }

    func turnOff(deviceId: String) async throws {
        try await mqttClient.publishCommand(deviceId: deviceId, payload: ["d1": .int(0)])
        cachedDevices[deviceId]?.d1 = 0
        cachedDevices[deviceId]?.powerSwitch = 0
    }

    func setBrightness(deviceId: String, value: Int) async throws {
        let deviceBrightness = LeproBrightness.homeAssistantToDevice(value)
        let device = cachedDevices[deviceId]
        var payload: [String: LeproCommandValue] = ["d1": .int(1)]

        if let device, isBModel(device) {
            if device.d2 == 1 {
                payload["d2"] = .int(1)
                payload["d5"] = .string(updatedD5(device.d5, brightness: deviceBrightness))
            } else {
                payload["d2"] = .int(0)
                payload["d3"] = .int(deviceBrightness)
                payload["d4"] = .int(device.d4 ?? 500)
            }
        } else {
            payload["d52"] = .int(deviceBrightness)
            if let d50 = device?.d50 {
                payload["d2"] = .int(2)
                payload["d50"] = .string(d50)
            }
        }

        try await mqttClient.publishCommand(deviceId: deviceId, payload: payload)
        cachedDevices[deviceId]?.d1 = 1
        cachedDevices[deviceId]?.powerSwitch = 1
        cachedDevices[deviceId]?.d52 = deviceBrightness
        if cachedDevices[deviceId]?.d3 != nil {
            cachedDevices[deviceId]?.d3 = deviceBrightness
        }
    }

    func setColor(deviceId: String, color: RGBColor, brightness: Int) async throws {
        let device = cachedDevices[deviceId]
        let deviceBrightness = LeproBrightness.homeAssistantToDevice(brightness)
        var payload: [String: LeproCommandValue] = ["d1": .int(1)]

        if let device, isBModel(device) {
            if isWhiteLike(color) {
                payload["d2"] = .int(0)
                payload["d3"] = .int(deviceBrightness)
                payload["d4"] = .int(device.d4 ?? 500)
            } else {
                payload["d2"] = .int(1)
                payload["d5"] = .string(buildBRGBD5(color: color, brightness: deviceBrightness))
            }
        } else {
            payload["d2"] = .int(2)
            payload["d52"] = .int(deviceBrightness)
            payload["d50"] = .string(LeproD50Codec.solid(color))
        }

        try await mqttClient.publishCommand(deviceId: deviceId, payload: payload)
        cachedDevices[deviceId]?.d1 = 1
        cachedDevices[deviceId]?.powerSwitch = 1
        cachedDevices[deviceId]?.d52 = deviceBrightness
        if let device = cachedDevices[deviceId], isBModel(device) {
            if isWhiteLike(color) {
                cachedDevices[deviceId]?.d2 = 0
                cachedDevices[deviceId]?.d3 = deviceBrightness
                cachedDevices[deviceId]?.d4 = device.d4 ?? 500
            } else {
                cachedDevices[deviceId]?.d2 = 1
                cachedDevices[deviceId]?.d5 = buildBRGBD5(color: color, brightness: deviceBrightness)
            }
        } else {
            cachedDevices[deviceId]?.d2 = 2
            cachedDevices[deviceId]?.d50 = LeproD50Codec.solid(color)
        }
    }

    func setSegmentColors(deviceId: String, colors: [RGBColor], brightness: Int) async throws {
        if let device = cachedDevices[deviceId], isBModel(device) {
            throw LeproError.commandFailed("Segment color control is only available for segmented strip devices.")
        }

        let deviceBrightness = LeproBrightness.homeAssistantToDevice(brightness)
        let d50 = LeproD50Codec.generate(colors: colors)
        let payload: [String: LeproCommandValue] = [
            "d1": .int(1),
            "d2": .int(2),
            "d52": .int(deviceBrightness),
            "d50": .string(d50)
        ]

        try await mqttClient.publishCommand(deviceId: deviceId, payload: payload)
        cachedDevices[deviceId]?.d1 = 1
        cachedDevices[deviceId]?.powerSwitch = 1
        cachedDevices[deviceId]?.d2 = 2
        cachedDevices[deviceId]?.d52 = deviceBrightness
        cachedDevices[deviceId]?.d50 = d50
    }

    private func fetchUserProfile() async throws -> UserProfileData {
        guard let session else { throw LeproError.missingSession }
        let timestamp = LeproHeaderFactory.timestamp()
        var request = URLRequest(url: URL(string: "https://\(session.region.apiHost)/user/profile")!)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = LeproHeaderFactory.headers(
            apiHost: session.region.apiHost,
            language: session.language,
            timestamp: timestamp,
            token: session.token
        )
        let response: UserProfileResponse = try await send(request)
        guard let data = response.data else {
            throw LeproError.invalidResponse("User profile response did not contain data")
        }
        return data
    }

    private func fetchFirstFamilyId() async throws -> String {
        guard let session else { throw LeproError.missingSession }
        let timestamp = LeproHeaderFactory.timestamp()
        var request = URLRequest(url: URL(string: "https://\(session.region.apiHost)/family/list/timestamp/\(timestamp)")!)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = LeproHeaderFactory.headers(
            apiHost: session.region.apiHost,
            language: session.language,
            timestamp: timestamp,
            token: session.token
        )
        let response: FamilyListResponse = try await send(request)
        guard let fid = response.data?.list.first?.fid.stringValue else {
            throw LeproError.invalidResponse("Family list response did not contain data.list[0].fid")
        }
        return fid
    }

    private func fetchDevices(fid: String) async throws -> [LeproDevice] {
        guard let session else { throw LeproError.missingSession }
        let timestamp = LeproHeaderFactory.timestamp()
        var request = URLRequest(url: URL(string: "https://\(session.region.apiHost)/v3/device/list/fid/\(fid)/timestamp/\(timestamp)")!)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = LeproHeaderFactory.headers(
            apiHost: session.region.apiHost,
            language: session.language,
            timestamp: timestamp,
            token: session.token
        )
        let response: DeviceListResponse = try await send(request)
        return response.data?.list ?? []
    }

    private func downloadCertificate(from url: URL) async throws -> Data {
        guard let session else { throw LeproError.missingSession }
        let timestamp = LeproHeaderFactory.timestamp()
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = LeproHeaderFactory.headers(
            apiHost: session.region.apiHost,
            language: session.language,
            timestamp: timestamp,
            token: session.token
        )

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await urlSession.data(for: request)
        } catch {
            throw LeproError.networkError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LeproError.invalidResponse("Certificate request did not return HTTPURLResponse")
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            throw mapHTTPError(httpResponse.statusCode, body: data)
        }
        return data
    }

    private func prepareMQTTIfNeeded(bundle: LeproCertificateBundle) async throws {
        guard !mqttPrepared else { return }
        guard let session, let mqttInfo else { throw LeproError.invalidResponse("Missing MQTT info from user profile") }

        let identity = try MTLSIdentityBuilder.makeIdentity(
            clientCertificatePEM: bundle.clientCertificatePEM,
            privateKeyPEM: bundle.privateKeyPEM
        )
        let rootCertificate = try MTLSIdentityBuilder.makeRootCertificate(rootCertificatePEM: bundle.rootCertificatePEM)
        let clientIdSuffix = sha256Hex(session.account + session.createdAt.description).prefix(32)
        let clientId = "lepro-app-\(clientIdSuffix)"

        try await mqttClient.connect(
            host: mqttInfo.host,
            port: mqttInfo.port.intValue ?? 8883,
            clientId: clientId,
            identity: identity,
            rootCertificate: rootCertificate
        )
        mqttPrepared = true
    }

    private func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await urlSession.data(for: request)
        } catch {
            throw LeproError.networkError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LeproError.invalidResponse("Request did not return HTTPURLResponse")
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            throw mapHTTPError(httpResponse.statusCode, body: data)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            let sample = String(data: data.prefix(500), encoding: .utf8) ?? "<binary>"
            print("Decode error: \(error). Body sample: \(sample)")
            throw LeproError.invalidResponse(error.localizedDescription)
        }
    }

    private func mapHTTPError(_ statusCode: Int, body: Data) -> LeproError {
        let bodyText = String(data: body.prefix(500), encoding: .utf8) ?? ""
        print("Lepro HTTP \(statusCode): \(bodyText)")
        if let cloudError = try? decoder.decode(LeproCloudErrorResponse.self, from: body) {
            if cloudError.code == -203 || cloudError.msg?.localizedCaseInsensitiveContains("invalid password") == true {
                return .invalidCredentials
            }
            if cloudError.code == -905 {
                return .requestThrottled
            }
        }
        if statusCode == 401 || statusCode == 403 {
            return .unauthorized
        }
        return .networkError("HTTP \(statusCode)")
    }

    private func isBModel(_ device: LeproDevice) -> Bool {
        let model = (device.series ?? "").uppercased()
        return ["B1", "BC1", "B2", "B3", "T1", "BP1", "SE1"].contains { model.contains($0) }
    }

    private func updatedD5(_ currentD5: String?, brightness: Int) -> String {
        let valueHex = String(format: "%04X", max(0, min(1000, brightness)))
        guard let currentD5, currentD5.count >= 8 else {
            return "000003E8\(valueHex)"
        }
        return "\(currentD5.prefix(8))\(valueHex)"
    }

    private func buildBRGBD5(color: RGBColor, brightness: Int) -> String {
        let hue = rgbHueDegrees(red: color.red, green: color.green, blue: color.blue)
        let valueHex = String(format: "%04X", max(0, min(1000, brightness)))
        return String(format: "%04X03E8%@", hue, valueHex)
    }

    private func isWhiteLike(_ color: RGBColor) -> Bool {
        let maxChannel = max(color.red, color.green, color.blue)
        let minChannel = min(color.red, color.green, color.blue)
        return maxChannel - minChannel <= 12
    }

    private func rgbHueDegrees(red: Int, green: Int, blue: Int) -> Int {
        let r = Double(max(0, min(255, red))) / 255.0
        let g = Double(max(0, min(255, green))) / 255.0
        let b = Double(max(0, min(255, blue))) / 255.0
        let maxValue = max(r, g, b)
        let minValue = min(r, g, b)
        let delta = maxValue - minValue

        guard delta > 0 else {
            return 0
        }

        let hue: Double
        if maxValue == r {
            hue = 60.0 * (((g - b) / delta).truncatingRemainder(dividingBy: 6.0))
        } else if maxValue == g {
            hue = 60.0 * (((b - r) / delta) + 2.0)
        } else {
            hue = 60.0 * (((r - g) / delta) + 4.0)
        }

        let normalized = hue < 0 ? hue + 360.0 : hue
        return Int(round(normalized)) % 360
    }

    private func sha256Hex(_ text: String) -> String {
        SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
