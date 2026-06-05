import Foundation

enum MQTTCodec {
    nonisolated static func connectPacket(clientId: String, keepAlive: UInt16 = 60) -> Data {
        var variableAndPayload = Data()
        variableAndPayload.appendUTF8String("MQTT")
        variableAndPayload.append(0x04)
        variableAndPayload.append(0x02)
        variableAndPayload.appendUInt16(keepAlive)
        variableAndPayload.appendUTF8String(clientId)

        var packet = Data([0x10])
        packet.append(remainingLength(variableAndPayload.count))
        packet.append(variableAndPayload)
        return packet
    }

    nonisolated static func publishPacket(topic: String, payload: Data) -> Data {
        var variableAndPayload = Data()
        variableAndPayload.appendUTF8String(topic)
        variableAndPayload.append(payload)

        var packet = Data([0x30])
        packet.append(remainingLength(variableAndPayload.count))
        packet.append(variableAndPayload)
        return packet
    }

    nonisolated static func isSuccessfulConnack(_ data: Data) -> Bool {
        let bytes = [UInt8](data)
        return bytes.count >= 4 && bytes[0] == 0x20 && bytes[1] == 0x02 && bytes[3] == 0x00
    }

    nonisolated static func disconnectPacket() -> Data {
        Data([0xE0, 0x00])
    }

    nonisolated private static func remainingLength(_ length: Int) -> Data {
        var value = length
        var encoded = Data()
        repeat {
            var byte = UInt8(value % 128)
            value /= 128
            if value > 0 {
                byte |= 128
            }
            encoded.append(byte)
        } while value > 0
        return encoded
    }
}

extension Data {
    nonisolated mutating func appendUInt16(_ value: UInt16) {
        append(UInt8((value >> 8) & 0xff))
        append(UInt8(value & 0xff))
    }

    nonisolated mutating func appendUTF8String(_ string: String) {
        let data = Data(string.utf8)
        appendUInt16(UInt16(data.count))
        append(data)
    }
}
