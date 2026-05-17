import Combine
import Foundation

final class MenuBarHidingController: ObservableObject {
    @Published private(set) var isExpanded = false
    @Published private(set) var detectedItems: [MenuBarItemDescriptor] = []

    private let itemProvider: MenuBarItemProviding
    private let hiddenItemsStore: HiddenItemsStore

    init(itemProvider: MenuBarItemProviding, hiddenItemsStore: HiddenItemsStore) {
        self.itemProvider = itemProvider
        self.hiddenItemsStore = hiddenItemsStore
    }

    func refreshDetectedItems() {
        // TODO: implement in Phase 2 by enumerating live menu bar items.
        detectedItems = itemProvider.currentItems()
    }

    func toggleExpanded() {
        isExpanded.toggle()
        applyHiddenState()
    }

    func applyHiddenState() {
        // TODO: implement in Phase 2.
        // When collapsed, move selected hidden items out of the visible menu bar.
        // When expanded, restore those items inline along the menu bar.
        // The movement mechanism is intentionally undecided after Phase 1.
        _ = hiddenItemsStore.hiddenItemIDs
    }
}
