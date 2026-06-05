import Foundation
import Network
import Security

final class LeproMQTTClient {
    private let queue = DispatchQueue(label: "ferrerlabs.leprocontrol.mqtt")
    private var connection: NWConnection?
    private var isConnected = false
    private let encoder = JSONEncoder()

    func connect(host: String, port: Int, clientId: String, identity: SecIdentity, rootCertificate: SecCertificate) async throws {
        if isConnected {
            return
        }

        let tlsOptions = NWProtocolTLS.Options()
        if let secIdentity = sec_identity_create(identity) {
            sec_protocol_options_set_local_identity(tlsOptions.securityProtocolOptions, secIdentity)
        } else {
            throw LeproError.invalidResponse("Could not bridge SecIdentity for Network TLS")
        }

        sec_protocol_options_set_verify_block(tlsOptions.securityProtocolOptions, { _, secTrust, complete in
            let trust = sec_trust_copy_ref(secTrust).takeRetainedValue()
            SecTrustSetAnchorCertificates(trust, [rootCertificate] as CFArray)
            SecTrustSetAnchorCertificatesOnly(trust, false)
            var trustError: CFError?
            complete(SecTrustEvaluateWithError(trust, &trustError))
        }, queue)

        let parameters = NWParameters(tls: tlsOptions, tcp: NWProtocolTCP.Options())
        let connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(integerLiteral: UInt16(port)), using: parameters)
        self.connection = connection

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            var didResume = false
            func resume(_ result: Result<Void, Error>) {
                queue.async {
                    guard !didResume else { return }
                    didResume = true
                    switch result {
                    case .success:
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }

            connection.stateUpdateHandler = { [weak self] state in
                guard let self else { return }
                switch state {
                case .ready:
                    let packet = MQTTCodec.connectPacket(clientId: clientId)
                    connection.send(content: packet, completion: .contentProcessed { error in
                        if let error {
                            resume(.failure(LeproError.networkError(error.localizedDescription)))
                            return
                        }
                        connection.receive(minimumIncompleteLength: 4, maximumLength: 4) { data, _, _, receiveError in
                            if let receiveError {
                                resume(.failure(LeproError.networkError(receiveError.localizedDescription)))
                                return
                            }
                            guard let data, MQTTCodec.isSuccessfulConnack(data) else {
                                resume(.failure(LeproError.commandFailed("MQTT broker rejected CONNECT")))
                                return
                            }
                            self.isConnected = true
                            resume(.success(()))
                        }
                    })
                case .failed(let error):
                    resume(.failure(LeproError.networkError(error.localizedDescription)))
                case .cancelled:
                    resume(.failure(LeproError.networkError("MQTT connection cancelled")))
                default:
                    break
                }
            }

            connection.start(queue: queue)
        }
    }

    func publishCommand(deviceId: String, payload: [String: LeproCommandValue]) async throws {
        guard let connection, isConnected else {
            throw LeproError.mqttNotReady
        }

        let envelope = MqttCommandEnvelope(
            id: Int.random(in: 0...1_000_000_000),
            t: Int(Date().timeIntervalSince1970),
            d: payload
        )
        let data = try encoder.encode(envelope)
        let packet = MQTTCodec.publishPacket(topic: "le/\(deviceId)/prp/set", payload: data)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            connection.send(content: packet, completion: .contentProcessed { error in
                if let error {
                    continuation.resume(throwing: LeproError.commandFailed(error.localizedDescription))
                } else {
                    continuation.resume()
                }
            })
        }
    }

    func disconnect() {
        isConnected = false
        guard let connection else {
            return
        }

        connection.send(content: MQTTCodec.disconnectPacket(), completion: .contentProcessed { _ in
            connection.cancel()
        })
        self.connection = nil
    }
}
