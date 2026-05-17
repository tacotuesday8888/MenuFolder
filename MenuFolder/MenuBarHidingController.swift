import Combine
import Foundation

final class MenuBarHidingController: ObservableObject {
    @Published private(set) var isExpanded = false
    @Published private(set) var detectedItems: [MenuBarItemDescriptor] = []
    @Published private(set) var moveFailuresByItemID: [String: String] = [:]

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
        let report = itemHider.applyHiddenState(
            hiddenItemIDs: hiddenItemsStore.hiddenItemIDs,
            isExpanded: isExpanded
        )
        moveFailuresByItemID = report.failedItemMessagesByID
        refreshDetectedItems()
    }

    func restoreHiddenItems() {
        let report = itemHider.restoreHiddenItems(hiddenItemIDs: hiddenItemsStore.hiddenItemIDs)
        moveFailuresByItemID = report.failedItemMessagesByID
        isExpanded = true
        refreshDetectedItems()
    }
}
