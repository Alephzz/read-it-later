import Foundation

/// 解析逗号分隔的标签输入：兼容中英文逗号、分号，去空白并过滤空串
enum TagParser {
    static func parse(_ input: String) -> [String] {
        input
            .split { $0 == "," || $0 == "，" || $0 == ";" || $0 == "；" }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
