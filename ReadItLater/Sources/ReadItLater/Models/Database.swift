import Foundation
import SQLite3

final class DatabaseService {
    static let shared = DatabaseService()

    private var db: OpaquePointer?
    private let dbPath: String

    private init() {
        let appSupport = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first!
        let appDir = (appSupport as NSString).appendingPathComponent("ReadItLater")
        try? FileManager.default.createDirectory(atPath: appDir, withIntermediateDirectories: true)
        dbPath = (appDir as NSString).appendingPathComponent("data.sqlite")
    }

    func initialize() {
        guard sqlite3_open(dbPath, &db) == SQLITE_OK else {
            print("Failed to open database: \(String(cString: sqlite3_errmsg(db)))")
            return
        }
        createTable()
    }

    deinit {
        sqlite3_close(db)
    }

    private func createTable() {
        let sql = """
        CREATE TABLE IF NOT EXISTS items (
            id TEXT PRIMARY KEY,
            url TEXT,
            content TEXT NOT NULL,
            title TEXT NOT NULL,
            summary TEXT,
            faviconData BLOB,
            domain TEXT NOT NULL,
            tags TEXT NOT NULL DEFAULT '[]',
            status INTEGER NOT NULL DEFAULT 0,
            createdAt REAL NOT NULL,
            readAt REAL
        )
        """
        executeSQL(sql)
    }

    // MARK: - CRUD

    func save(_ item: Item) throws {
        let sql = """
        INSERT OR REPLACE INTO items (id, url, content, title, summary, faviconData, domain, tags, status, createdAt, readAt)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, item.id.uuidString, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        bindOptionalText(stmt, 2, item.url)
        sqlite3_bind_text(stmt, 3, item.content, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_text(stmt, 4, item.title, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        bindOptionalText(stmt, 5, item.summary)
        bindOptionalBlob(stmt, 6, item.faviconData)
        sqlite3_bind_text(stmt, 7, item.domain, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_text(stmt, 8, tagsToJSON(item.tags), -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_int(stmt, 9, Int32(item.status.rawValue))
        sqlite3_bind_double(stmt, 10, item.createdAt.timeIntervalSince1970)
        sqlite3_bind_double(stmt, 11, item.readAt?.timeIntervalSince1970 ?? 0)

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw DatabaseError.stepFailed(String(cString: sqlite3_errmsg(db)))
        }
    }

    func fetchAll() -> [Item] {
        let sql = "SELECT * FROM items ORDER BY createdAt DESC"
        return queryItems(sql)
    }

    func fetchUnread() -> [Item] {
        let sql = "SELECT * FROM items WHERE status = 0 ORDER BY createdAt DESC"
        return queryItems(sql)
    }

    func fetchPending() -> [Item] {
        // 待处理 = 未读 + 在读（还没读完的都算）
        let sql = "SELECT * FROM items WHERE status != 2 ORDER BY createdAt DESC"
        return queryItems(sql)
    }

    /// 归一化查重：去掉 utm 等追踪参数、尾斜杠后比较（见 DuplicateDetector）
    func existsNormalized(url: String) -> Bool {
        DuplicateDetector.isDuplicate(url: url, existingItems: fetchAll())
    }

    func updateStatus(id: UUID, status: ItemStatus) {
        let sql = "UPDATE items SET status = ?, readAt = ? WHERE id = ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_int(stmt, 1, Int32(status.rawValue))
        sqlite3_bind_double(stmt, 2, status == .done ? Date().timeIntervalSince1970 : 0)
        sqlite3_bind_text(stmt, 3, id.uuidString, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_step(stmt)
    }

    func updateItem(_ item: Item) {
        try? save(item) // INSERT OR REPLACE handles update
    }

    /// 批量保存（导入用）：按 id 幂等合并，同 id 覆盖、新 id 插入
    func saveItems(_ items: [Item]) {
        for item in items {
            try? save(item)
        }
    }

    func delete(id: UUID) {
        let sql = "DELETE FROM items WHERE id = ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, id.uuidString, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_step(stmt)
    }

    // MARK: - Helpers

    private func queryItems(_ sql: String) -> [Item] {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }

        var items: [Item] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let item = itemFromRow(stmt)
            items.append(item)
        }
        return items
    }

    private func itemFromRow(_ stmt: OpaquePointer?) -> Item {
        let id = UUID(uuidString: textColumn(stmt, 0) ?? "") ?? UUID()
        let url = textColumn(stmt, 1)
        let content = textColumn(stmt, 2) ?? ""
        let title = textColumn(stmt, 3) ?? ""
        let summary = textColumn(stmt, 4)
        let faviconData = blobColumn(stmt, 5)
        let domain = textColumn(stmt, 6) ?? "unknown"
        let tags = tagsFromJSON(textColumn(stmt, 7) ?? "[]")
        let status = ItemStatus(rawValue: Int(sqlite3_column_int(stmt, 8))) ?? .unread
        let createdAt = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 9))
        let readAtValue = sqlite3_column_double(stmt, 10)
        let readAt = readAtValue > 0 ? Date(timeIntervalSince1970: readAtValue) : nil

        return Item(
            id: id, url: url, content: content, title: title,
            summary: summary, faviconData: faviconData, domain: domain,
            tags: tags, status: status, createdAt: createdAt, readAt: readAt
        )
    }

    private func executeSQL(_ sql: String) {
        var errMsg: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, sql, nil, nil, &errMsg) != SQLITE_OK {
            let msg = errMsg.map { String(cString: $0) } ?? "Unknown error"
            print("SQL error: \(msg)")
            sqlite3_free(errMsg)
        }
    }

    private func textColumn(_ stmt: OpaquePointer?, _ col: Int32) -> String? {
        guard let cStr = sqlite3_column_text(stmt, col) else { return nil }
        return String(cString: cStr)
    }

    private func blobColumn(_ stmt: OpaquePointer?, _ col: Int32) -> Data? {
        guard let ptr = sqlite3_column_blob(stmt, col) else { return nil }
        let len = sqlite3_column_bytes(stmt, col)
        return Data(bytes: ptr, count: Int(len))
    }

    private func bindOptionalText(_ stmt: OpaquePointer?, _ col: Int32, _ value: String?) {
        if let v = value {
            sqlite3_bind_text(stmt, col, v, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        } else {
            sqlite3_bind_null(stmt, col)
        }
    }

    private func bindOptionalBlob(_ stmt: OpaquePointer?, _ col: Int32, _ data: Data?) {
        if let d = data {
            let _ = d.withUnsafeBytes { ptr -> Int32 in
                sqlite3_bind_blob(stmt, col, ptr.baseAddress, Int32(d.count), unsafeBitCast(-1, to: sqlite3_destructor_type.self))
            }
        } else {
            sqlite3_bind_null(stmt, col)
        }
    }

    private func tagsToJSON(_ tags: [String]) -> String {
        (try? String(data: JSONEncoder().encode(tags), encoding: .utf8)) ?? "[]"
    }

    private func tagsFromJSON(_ json: String) -> [String] {
        (try? JSONDecoder().decode([String].self, from: Data(json.utf8))) ?? []
    }
}

enum DatabaseError: Error {
    case prepareFailed(String)
    case stepFailed(String)
}
