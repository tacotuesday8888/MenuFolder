import Combine
import Foundation

final class MenuBarHidingController: ObservableObject {
    @Published private(set) var isExpanded = false
    @Published private(set) var detectedItems: [MenuBarItemDescriptor] = []

    private let itemProvider: MenuBarItemProviding
    private let itemHider: MenuBarItemHiding
    private let hiddenItemsStore: HiddenItemsStore

    init(
        itemProvider: MenuBarItemProviding,
        itemHider: MenuBarItemHiding,
        hiddenItemsStore: HiddenItemsStore
    ) {
        self.itemProvider = itemProvider
        self.itemHider = itemHider
        self.hiddenItemsStore = hiddenItemsStore
    }

    func refreshDetectedItems() {
        detectedItems = itemProvider.currentItems()
    }

    func toggleExpanded() {
        isExpanded.toggle()
        applyHiddenState()
    }

    func applyHiddenState() {
        itemHider.applyHiddenState(
            hiddenItemIDs: hiddenItemsStore.hiddenItemIDs,
            isExpanded: isExpanded
        )
        refreshDetectedItems()
    }

    func restoreHiddenItems() {
        itemHider.restoreHiddenItems(hiddenItemIDs: hiddenItemsStore.hiddenItemIDs)
        isExpanded = true
        refreshDetectedItems()
    }
}
