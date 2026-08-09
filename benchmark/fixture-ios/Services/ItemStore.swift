import Foundation
import Combine

@MainActor
final class ItemStore: ObservableObject {
    @Published private(set) var items: [Item] = []

    private static let storageKey = "fixture.items.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([Item].self, from: data) {
            items = decoded
        } else {
            // Seed 5 item mặc định
            items = (1...5).map { Item(name: "Item \($0)") }
            save()
        }
    }

    func add(name: String) {
        items.append(Item(name: name))
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }
}
