import Foundation

struct MenuBarItemDescriptor: Identifiable, Hashable {
    let id: String
    let displayName: String
    let ownerName: String
    let isPlaceholder: Bool
}

protocol MenuBarItemProviding {
    func currentItems() -> [MenuBarItemDescriptor]
}

struct PlaceholderMenuBarItemProvider: MenuBarItemProviding {
    func currentItems() -> [MenuBarItemDescriptor] {
        [
            MenuBarItemDescriptor(
                id: "placeholder.calendar",
                displayName: "Calendar",
                ownerName: "Placeholder item",
                isPlaceholder: true
            ),
            MenuBarItemDescriptor(
                id: "placeholder.cloud-sync",
                displayName: "Cloud Sync",
                ownerName: "Placeholder item",
                isPlaceholder: true
            ),
            MenuBarItemDescriptor(
                id: "placeholder.focus",
                displayName: "Focus",
                ownerName: "Placeholder item",
                isPlaceholder: true
            )
        ]
    }
}
