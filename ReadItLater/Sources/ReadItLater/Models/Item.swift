import Foundation

enum ItemStatus: Int, Codable {
    case unread = 0
    case reading = 1
    case done = 2
}

struct Item: Identifiable, Equatable, Codable {
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
            let (agingDays, staleDays) = thresholds
            let days = Date().timeIntervalSince(date) / 86400
            if days < agingDays { return .fresh }
            if days < staleDays { return .aging }
            return .stale
        }

        /// 读取设置中的阈值（"变黄天数,变红天数"，默认 7,30）
        private static var thresholds: (aging: Double, stale: Double) {
            let defaults = (aging: 7.0, stale: 30.0)
            guard let raw = UserDefaults.standard.string(forKey: "stalenessDays") else {
                return defaults
            }
            let parts = raw.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
            guard parts.count == 2, parts[0] > 0, parts[1] > parts[0] else {
                return defaults
            }
            return (parts[0], parts[1])
        }
    }

    var staleness: Staleness {
        Staleness.from(date: createdAt)
    }
}
