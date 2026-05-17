import AppKit

final class MenuFolderStatusController: NSObject {
    private let permissionsManager: PermissionsManager
    private let hidingController: MenuBarHidingController
    private let windowCoordinator: WindowCoordinator
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

    private var permissionsTimer: Timer?

    init(
        permissionsManager: PermissionsManager,
        hidingController: MenuBarHidingController,
        windowCoordinator: WindowCoordinator
    ) {
        self.permissionsManager = permissionsManager
        self.hidingController = hidingController
        self.windowCoordinator = windowCoordinator
    }

    func start() {
        guard let button = statusItem.button else {
            return
        }

        button.target = self
        button.action = #selector(handleStatusItemClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.imagePosition = .imageOnly
        button.toolTip = "MenuFolder"
        updateStatusImage()

        permissionsTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.refreshPermissionsState()
        }
    }

    func refreshPermissionsState() {
        permissionsManager.refresh()
        updateStatusImage()
    }

    @objc private func handleStatusItemClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else {
            return
        }

        if event.type == .rightMouseUp {
            showContextMenu()
            return
        }

        if permissionsManager.hasRequiredPermissions {
            hidingController.toggleExpanded()
            updateStatusImage()
        } else {
            windowCoordinator.showPermissionsWindow()
        }
    }

    @objc private func showManagementWindow() {
        windowCoordinator.showManagementWindow()
    }

    @objc private func showPermissionsWindow() {
        windowCoordinator.showPermissionsWindow()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(
            title: "Manage hidden items...",
            action: #selector(showManagementWindow),
            keyEquivalent: ""
        ))
        menu.addItem(NSMenuItem(
            title: "Permissions...",
            action: #selector(showPermissionsWindow),
            keyEquivalent: ""
        ))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: "Quit MenuFolder",
            action: #selector(quit),
            keyEquivalent: "q"
        ))

        for item in menu.items {
            item.target = self
        }

        guard let button = statusItem.button else {
            return
        }

        menu.popUp(
            positioning: nil,
            at: NSPoint(x: 0, y: button.bounds.height),
            in: button
        )
    }

    private func updateStatusImage() {
        let hasWarning = !permissionsManager.hasRequiredPermissions
        statusItem.button?.image = StatusImageFactory.image(
            isExpanded: hidingController.isExpanded,
            hasWarning: hasWarning
        )
        statusItem.button?.toolTip = hasWarning ? "MenuFolder needs permissions" : "MenuFolder"
    }
}

private enum StatusImageFactory {
    static func image(isExpanded: Bool, hasWarning: Bool) -> NSImage? {
        let baseName = isExpanded ? "folder.fill" : "folder"
        guard let base = NSImage(
            systemSymbolName: baseName,
            accessibilityDescription: hasWarning ? "MenuFolder needs permissions" : "MenuFolder"
        ) else {
            return nil
        }

        guard hasWarning else {
            base.isTemplate = true
            return base
        }

        let image = NSImage(size: NSSize(width: 18, height: 18))
        image.lockFocus()

        let symbolConfig = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        let configuredBase = base.withSymbolConfiguration(symbolConfig) ?? base
        configuredBase.draw(
            in: NSRect(x: 0, y: 1, width: 16, height: 16),
            from: .zero,
            operation: .sourceOver,
            fraction: 1
        )

        NSColor.systemOrange.setFill()
        NSBezierPath(ovalIn: NSRect(x: 10.5, y: 0.5, width: 7, height: 7)).fill()

        let text = "!"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 6),
            .foregroundColor: NSColor.white
        ]
        text.draw(at: NSPoint(x: 12.7, y: 0.2), withAttributes: attributes)

        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}
