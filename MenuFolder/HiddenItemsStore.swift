import Combine
import Foundation

final class HiddenItemsStore: ObservableObject {
    private enum Keys {
        static let hiddenItemIDs = "MenuFolder.hiddenItemIDs"
        static let hasShownPermissionsWelcome = "MenuFolder.hasShownPermissionsWelcome"
    }

    @Published private(set) var hiddenItemIDs: Set<String>

    var hasShownPermissionsWelcome: Bool {
        get {
            UserDefaults.standard.bool(forKey: Keys.hasShownPermissionsWelcome)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.hasShownPermissionsWelcome)
        }
    }

    init() {
        let storedIDs = UserDefaults.standard.stringArray(forKey: Keys.hiddenItemIDs) ?? []
        hiddenItemIDs = Set(storedIDs)
    }

    func isHidden(_ itemID: String) -> Bool {
        hiddenItemIDs.contains(itemID)
    }

    func setHidden(_ isHidden: Bool, for itemID: String) {
        if isHidden {
            hiddenItemIDs.insert(itemID)
        } else {
            hiddenItemIDs.remove(itemID)
        }
        persistHiddenItemIDs()
    }

    private func persistHiddenItemIDs() {
        UserDefaults.standard.set(Array(hiddenItemIDs).sorted(), forKey: Keys.hiddenItemIDs)
    }
}
