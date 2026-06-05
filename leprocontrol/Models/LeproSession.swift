import Foundation

struct LeproSession: Codable, Equatable {
    let account: String
    let token: String
    let region: LeproRegion
    let language: String
    let mac: String
    let createdAt: Date
}
