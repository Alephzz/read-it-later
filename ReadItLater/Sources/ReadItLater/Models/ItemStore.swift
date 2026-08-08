import Foundation
import SwiftUI

class ItemStore: ObservableObject {
    @Published var items: [Item] = []

    private let database = DatabaseService.shared

    init() {
        refresh()
    }

    func refresh() {
        items = database.fetchAll()
    }

    func updateStatus(id: UUID, status: ItemStatus) {
        database.updateStatus(id: id, status: status)
        refresh()
    }

    func delete(id: UUID) {
        database.delete(id: id)
        refresh()
    }

    func save(_ item: Item) {
        try? database.save(item)
        refresh()
    }

    func update(_ item: Item) {
        database.updateItem(item)
        refresh()
    }
}
