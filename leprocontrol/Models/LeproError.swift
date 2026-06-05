import Foundation

enum LeproError: LocalizedError, Equatable {
    case invalidCredentials
    case unauthorized
    case networkError(String)
    case invalidResponse(String)
    case deviceOffline
    case commandFailed(String)
    case missingSession
    case mqttNotReady
    case requestThrottled
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            "Invalid Lepro account or password."
        case .unauthorized:
            "The Lepro session is no longer authorized. Please log in again."
        case .networkError(let message):
            "Network error: \(message)"
        case .invalidResponse(let message):
            "Unexpected Lepro response: \(message)"
        case .deviceOffline:
            "The selected device appears to be offline."
        case .commandFailed(let message):
            "Could not send the command: \(message)"
        case .missingSession:
            "No saved Lepro session was found."
        case .mqttNotReady:
            "The MQTT control channel is not ready yet."
        case .requestThrottled:
            "Lepro Cloud is throttling requests. Wait a moment before refreshing again."
        case .unknown(let message):
            "Unexpected error: \(message)"
        }
    }

    var userMessage: String {
        switch self {
        case .invalidCredentials:
            "Usuario o contraseña incorrectos."
        case .unauthorized, .missingSession:
            "La sesión ha caducado. Inicia sesión de nuevo."
        case .networkError:
            "No se pudo conectar con Lepro Cloud."
        case .invalidResponse:
            "Lepro Cloud devolvió una respuesta inesperada."
        case .deviceOffline:
            "El dispositivo parece estar offline."
        case .commandFailed:
            "No se pudo enviar el comando al dispositivo."
        case .mqttNotReady:
            "El canal de control MQTT aún no está listo."
        case .requestThrottled:
            "Lepro Cloud está limitando las peticiones. Espera unos segundos antes de refrescar."
        case .unknown:
            "Ha ocurrido un error inesperado."
        }
    }
}
