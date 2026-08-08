import Foundation

enum ItemStatus: Int, Codable {
    case unread = 0
    case reading = 1
    case done = 2
}

struct Item: Identifiable, Equatable {
    var id: UUID
    var url: String?
    var content: String
    var title: String
    var summary: String?
    var faviconData: Data?
    var domain: String
    var tags: [String]
    var status: ItemStatus
    var createdAt: Date
    var readAt: Date?

    // MARK: - Staleness

    enum Staleness {
        case fresh, aging, stale

        static func from(date: Date) -> Staleness {
            let days = Date().timeIntervalSince(date) / 86400
            if days < 7 { return .fresh }
            if days < 30 { return .aging }
            return .stale
        }
    }

    var staleness: Staleness {
        Staleness.from(date: createdAt)
    }
}
