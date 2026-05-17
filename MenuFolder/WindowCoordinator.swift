import AppKit
import SwiftUI

final class WindowCoordinator {
    private let permissionsManager: PermissionsManager
    private let hiddenItemsStore: HiddenItemsStore
    private let hidingController: MenuBarHidingController

    private var permissionsWindow: NSWindow?
    private var managementWindow: NSWindow?

    init(
        permissionsManager: PermissionsManager,
        hiddenItemsStore: HiddenItemsStore,
        hidingController: MenuBarHidingController
    ) {
        self.permissionsManager = permissionsManager
        self.hiddenItemsStore = hiddenItemsStore
        self.hidingController = hidingController
    }

    func showPermissionsWindow() {
        permissionsManager.refresh()

        if permissionsWindow == nil {
            let view = PermissionsWelcomeView(permissionsManager: permissionsManager) { [weak self] in
                guard let self else {
                    return
                }

                self.permissionsManager.refresh()
                if self.permissionsManager.hasRequiredPermissions {
                    self.hidingController.refreshDetectedItems()
                    self.hidingController.applyHiddenState()
                }
                self.permissionsWindow?.close()
            }
            permissionsWindow = makeWindow(
                title: "MenuFolder Permissions",
                contentView: view,
                size: NSSize(width: 500, height: 360)
            )
        }

        show(permissionsWindow)
    }

    func showManagementWindow() {
        hidingController.refreshDetectedItems()

        if managementWindow == nil {
            let view = ManageHiddenItemsView(
                hidingController: hidingController,
                hiddenItemsStore: hiddenItemsStore
            )
            managementWindow = makeWindow(
                title: "Manage Hidden Items",
                contentView: view,
                size: NSSize(width: 420, height: 340)
            )
        }

        show(managementWindow)
    }

    private func makeWindow<Content: View>(
        title: String,
        contentView: Content,
        size: NSSize
    ) -> NSWindow {
        let hostingController = NSHostingController(rootView: contentView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = title
        window.setContentSize(size)
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()
        return window
    }

    private func show(_ window: NSWindow?) {
        guard let window else {
            return
        }

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}
