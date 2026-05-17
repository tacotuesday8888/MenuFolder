import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let permissionsManager = PermissionsManager()
    private let hiddenItemsStore = HiddenItemsStore()
    private let menuBarItemController = AccessibilityMenuBarItemController()

    private lazy var hidingController = MenuBarHidingController(
        itemProvider: menuBarItemController,
        itemHider: menuBarItemController,
        hiddenItemsStore: hiddenItemsStore
    )

    private lazy var windowCoordinator = WindowCoordinator(
        permissionsManager: permissionsManager,
        hiddenItemsStore: hiddenItemsStore,
        hidingController: hidingController
    )

    private lazy var statusController = MenuFolderStatusController(
        permissionsManager: permissionsManager,
        hidingController: hidingController,
        windowCoordinator: windowCoordinator
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        hidingController.refreshDetectedItems()
        if permissionsManager.hasRequiredPermissions {
            hidingController.applyHiddenState()
        }
        statusController.start()

        if !hiddenItemsStore.hasShownPermissionsWelcome || !permissionsManager.hasRequiredPermissions {
            hiddenItemsStore.hasShownPermissionsWelcome = true
            windowCoordinator.showPermissionsWindow()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
