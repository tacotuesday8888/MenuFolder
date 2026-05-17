import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

struct MenuBarItemDescriptor: Identifiable, Hashable {
    let id: String
    let displayName: String
    let ownerName: String
    let bundleIdentifier: String?
    let processIdentifier: pid_t?
    let frame: CGRect?
    let isPlaceholder: Bool

    init(
        id: String,
        displayName: String,
        ownerName: String,
        bundleIdentifier: String? = nil,
        processIdentifier: pid_t? = nil,
        frame: CGRect? = nil,
        isPlaceholder: Bool = false
    ) {
        self.id = id
        self.displayName = displayName
        self.ownerName = ownerName
        self.bundleIdentifier = bundleIdentifier
        self.processIdentifier = processIdentifier
        self.frame = frame
        self.isPlaceholder = isPlaceholder
    }

    static func == (lhs: MenuBarItemDescriptor, rhs: MenuBarItemDescriptor) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

protocol MenuBarItemProviding {
    func currentItems() -> [MenuBarItemDescriptor]
}

struct MenuBarItemHidingReport {
    var movedItemIDs: Set<String> = []
    var failedItemMessagesByID: [String: String] = [:]

    var hasFailures: Bool {
        !failedItemMessagesByID.isEmpty
    }

    mutating func recordMove(for itemID: String) {
        movedItemIDs.insert(itemID)
        failedItemMessagesByID[itemID] = nil
    }

    mutating func recordFailure(_ message: String, for itemID: String) {
        failedItemMessagesByID[itemID] = message
    }
}

protocol MenuBarItemHiding {
    func applyHiddenState(hiddenItemIDs: Set<String>, isExpanded: Bool) -> MenuBarItemHidingReport
    func restoreHiddenItems(hiddenItemIDs: Set<String>) -> MenuBarItemHidingReport
}

final class AccessibilityMenuBarItemController: MenuBarItemProviding, MenuBarItemHiding {
    private enum Keys {
        static let restoreOriginsByItemID = "MenuFolder.restoreOriginsByItemID"
    }

    var expansionAnchorFrameProvider: (() -> CGRect?)?

    private var cachedItemsByID: [String: AccessibilityMenuBarItem] = [:]
    private var restoreOriginsByID: [String: CGPoint] = [:]
    private var lastVisibleOriginsByID: [String: CGPoint] = [:]

    init() {
        restoreOriginsByID = Self.loadRestoreOrigins()
    }

    func currentItems() -> [MenuBarItemDescriptor] {
        let items = enumerateItems()
        cachedItemsByID = Dictionary(uniqueKeysWithValues: items.map { ($0.descriptor.id, $0) })
        rememberVisibleOrigins(for: items)
        return items.map(\.descriptor)
    }

    func applyHiddenState(hiddenItemIDs: Set<String>, isExpanded: Bool) -> MenuBarItemHidingReport {
        let items = enumerateItems()
        cachedItemsByID = Dictionary(uniqueKeysWithValues: items.map { ($0.descriptor.id, $0) })
        rememberVisibleOrigins(for: items)

        var report = MenuBarItemHidingReport()

        if isExpanded {
            let selectedItems = items.filter { hiddenItemIDs.contains($0.descriptor.id) }
            expand(selectedItems, report: &report)
        }

        for item in items {
            let isSelected = hiddenItemIDs.contains(item.descriptor.id)

            if isExpanded && isSelected {
                continue
            }

            if isSelected {
                hide(item, report: &report)
            } else if restoreOriginsByID[item.descriptor.id] != nil {
                if restore(item, report: &report) {
                    forgetRestoreOrigin(for: item.descriptor.id)
                }
            }
        }

        return report
    }

    func restoreHiddenItems(hiddenItemIDs: Set<String>) -> MenuBarItemHidingReport {
        let items = enumerateItems()
        cachedItemsByID = Dictionary(uniqueKeysWithValues: items.map { ($0.descriptor.id, $0) })
        rememberVisibleOrigins(for: items)

        var report = MenuBarItemHidingReport()

        for item in items where hiddenItemIDs.contains(item.descriptor.id) || restoreOriginsByID[item.descriptor.id] != nil {
            if restore(item, report: &report) {
                forgetRestoreOrigin(for: item.descriptor.id)
            }
        }

        return report
    }

    private func hide(_ item: AccessibilityMenuBarItem, report: inout MenuBarItemHidingReport) {
        guard let frame = item.descriptor.frame else {
            report.recordFailure("MenuFolder could not read this item's position.", for: item.descriptor.id)
            return
        }

        rememberRestoreOriginIfNeeded(for: item)
        move(item, to: hiddenOrigin(for: frame), report: &report)
    }

    private func restore(_ item: AccessibilityMenuBarItem, report: inout MenuBarItemHidingReport) -> Bool {
        guard let origin = restoreOriginsByID[item.descriptor.id] else {
            return true
        }

        return move(item, to: origin, report: &report)
    }

    private func expand(_ selectedItems: [AccessibilityMenuBarItem], report: inout MenuBarItemHidingReport) {
        guard !selectedItems.isEmpty else {
            return
        }

        let sortedItems = selectedItems.sorted { lhs, rhs in
            originalVisibleOrigin(for: lhs).x < originalVisibleOrigin(for: rhs).x
        }
        guard let anchorFrame = expansionAnchorFrameProvider?() else {
            for item in sortedItems {
                _ = restore(item, report: &report)
            }
            return
        }

        var nextRightEdge = anchorFrame.minX
        for item in sortedItems.reversed() {
            guard let frame = item.descriptor.frame else {
                report.recordFailure("MenuFolder could not read this item's position.", for: item.descriptor.id)
                continue
            }

            rememberRestoreOriginIfNeeded(for: item)

            let width = max(frame.width, 1)
            let targetOrigin = CGPoint(
                x: nextRightEdge - width,
                y: originalVisibleOrigin(for: item).y
            )
            nextRightEdge = targetOrigin.x
            move(item, to: targetOrigin, report: &report)
        }
    }

    private func originalVisibleOrigin(for item: AccessibilityMenuBarItem) -> CGPoint {
        if let restoreOrigin = restoreOriginsByID[item.descriptor.id] {
            return restoreOrigin
        }
        if let visibleOrigin = lastVisibleOriginsByID[item.descriptor.id] {
            return visibleOrigin
        }
        return item.descriptor.frame?.origin ?? .zero
    }

    private func hiddenOrigin(for frame: CGRect) -> CGPoint {
        let leftmostScreenEdge = NSScreen.screens
            .map(\.frame.minX)
            .min() ?? 0
        return CGPoint(
            x: leftmostScreenEdge - frame.width - 16,
            y: frame.origin.y
        )
    }

    private func rememberRestoreOriginIfNeeded(for item: AccessibilityMenuBarItem) {
        guard restoreOriginsByID[item.descriptor.id] == nil else {
            return
        }

        restoreOriginsByID[item.descriptor.id] = originalVisibleOrigin(for: item)
        persistRestoreOrigins()
    }

    private func forgetRestoreOrigin(for itemID: String) {
        restoreOriginsByID[itemID] = nil
        persistRestoreOrigins()
    }

    private func persistRestoreOrigins() {
        let storedOrigins = restoreOriginsByID.mapValues { StoredMenuBarItemOrigin(point: $0) }
        guard let data = try? JSONEncoder().encode(storedOrigins) else {
            return
        }
        UserDefaults.standard.set(data, forKey: Keys.restoreOriginsByItemID)
    }

    private static func loadRestoreOrigins() -> [String: CGPoint] {
        guard let data = UserDefaults.standard.data(forKey: Keys.restoreOriginsByItemID),
              let storedOrigins = try? JSONDecoder().decode([String: StoredMenuBarItemOrigin].self, from: data) else {
            return [:]
        }

        return storedOrigins.mapValues(\.point)
    }

    private func rememberVisibleOrigins(for items: [AccessibilityMenuBarItem]) {
        for item in items {
            guard let frame = item.descriptor.frame,
                  frame.minX >= 0 else {
                continue
            }
            lastVisibleOriginsByID[item.descriptor.id] = frame.origin
        }
    }

    @discardableResult
    private func move(
        _ item: AccessibilityMenuBarItem,
        to position: CGPoint,
        report: inout MenuBarItemHidingReport
    ) -> Bool {
        guard setPosition(position, for: item) else {
            report.recordFailure("macOS refused to move this item.", for: item.descriptor.id)
            return false
        }

        report.recordMove(for: item.descriptor.id)
        return true
    }

    private func enumerateItems() -> [AccessibilityMenuBarItem] {
        let menuFolderBundleIdentifier = Bundle.main.bundleIdentifier
        let runningApplications = NSWorkspace.shared.runningApplications
            .filter { app in
                app.processIdentifier > 0
                    && !app.isTerminated
                    && app.bundleIdentifier != menuFolderBundleIdentifier
            }

        var rawItems = [RawAccessibilityMenuBarItem]()
        for app in runningApplications {
            rawItems.append(contentsOf: Self.menuBarItems(for: app))
        }

        return Self.uniqueItems(from: rawItems.sorted(by: Self.menuBarSort))
    }

    private static func menuBarItems(for app: NSRunningApplication) -> [RawAccessibilityMenuBarItem] {
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        guard let extrasMenuBar = copyElementAttribute(
            kAXExtrasMenuBarAttribute as CFString,
            from: appElement
        ) else {
            return []
        }

        let children = copyElementArrayAttribute(kAXChildrenAttribute as CFString, from: extrasMenuBar)
        guard !children.isEmpty else {
            return []
        }

        return children.compactMap { child in
            guard let frame = frame(for: child),
                  frame.width >= 4,
                  frame.height >= 4 else {
                return nil
            }

            let title = copyStringAttribute(kAXTitleAttribute as CFString, from: child) ?? ""
            let ownerName = app.localizedName ?? app.bundleIdentifier ?? "Unknown App"
            let displayName = displayName(
                title: title,
                ownerName: ownerName,
                bundleIdentifier: app.bundleIdentifier
            )

            return RawAccessibilityMenuBarItem(
                descriptor: MenuBarItemDescriptor(
                    id: "",
                    displayName: displayName,
                    ownerName: ownerName,
                    bundleIdentifier: app.bundleIdentifier,
                    processIdentifier: app.processIdentifier,
                    frame: frame
                ),
                element: child,
                title: title,
                frame: frame
            )
        }
    }

    private static func uniqueItems(from rawItems: [RawAccessibilityMenuBarItem]) -> [AccessibilityMenuBarItem] {
        var seenIDs: [String: Int] = [:]

        return rawItems.map { item in
            let baseID = stableID(for: item)
            let seenCount = seenIDs[baseID, default: 0] + 1
            seenIDs[baseID] = seenCount

            let id = seenCount == 1 ? baseID : "\(baseID).\(seenCount)"
            let descriptor = MenuBarItemDescriptor(
                id: id,
                displayName: item.descriptor.displayName,
                ownerName: item.descriptor.ownerName,
                bundleIdentifier: item.descriptor.bundleIdentifier,
                processIdentifier: item.descriptor.processIdentifier,
                frame: item.descriptor.frame
            )

            return AccessibilityMenuBarItem(
                descriptor: descriptor,
                element: item.element
            )
        }
    }

    private nonisolated static func menuBarSort(
        _ lhs: RawAccessibilityMenuBarItem,
        _ rhs: RawAccessibilityMenuBarItem
    ) -> Bool {
        if abs(lhs.frame.minY - rhs.frame.minY) > 1 {
            return lhs.frame.minY < rhs.frame.minY
        }

        return lhs.frame.minX < rhs.frame.minX
    }

    private static func stableID(for item: RawAccessibilityMenuBarItem) -> String {
        let appIdentity = item.descriptor.bundleIdentifier ?? item.descriptor.ownerName
        let itemIdentity = item.title.menuFolderTrimmed.nilIfEmpty ?? item.descriptor.displayName
        return "ax.\(normalizedIDComponent(appIdentity)).\(normalizedIDComponent(itemIdentity))"
    }

    private static func displayName(
        title: String,
        ownerName: String,
        bundleIdentifier: String?
    ) -> String {
        let cleanedTitle = title.menuFolderTrimmed
        guard !cleanedTitle.isEmpty else {
            return ownerName
        }

        switch (bundleIdentifier, cleanedTitle) {
        case ("com.apple.controlcenter", "BentoBox"):
            return "Control Center"
        case ("com.apple.controlcenter", "FocusModes"):
            return "Focus"
        case ("com.apple.controlcenter", "ScreenMirroring"):
            return "Screen Mirroring"
        case ("com.apple.controlcenter", "UserSwitcher"):
            return "Fast User Switching"
        case ("com.apple.controlcenter", "WiFi"):
            return "Wi-Fi"
        case ("com.apple.systemuiserver", "TimeMachine.TMMenuExtraHost"),
             ("com.apple.systemuiserver", "TimeMachineMenuExtra.TMMenuExtraHost"):
            return "Time Machine"
        default:
            return ownerName
        }
    }

    private static func frame(for element: AXUIElement) -> CGRect? {
        guard let origin = pointAttribute(kAXPositionAttribute as CFString, from: element),
              let size = sizeAttribute(kAXSizeAttribute as CFString, from: element) else {
            return nil
        }

        return CGRect(origin: origin, size: size)
    }

    private func setPosition(_ position: CGPoint, for item: AccessibilityMenuBarItem) -> Bool {
        var mutablePosition = position
        guard let axValue = AXValueCreate(.cgPoint, &mutablePosition) else {
            return false
        }

        let result = AXUIElementSetAttributeValue(
            item.element,
            kAXPositionAttribute as CFString,
            axValue
        )

        if result != .success {
            NSLog(
                "MenuFolder could not move menu bar item '%@' from '%@': AX error %d",
                item.descriptor.displayName,
                item.descriptor.ownerName,
                result.rawValue
            )
            return false
        }

        guard let updatedPosition = Self.pointAttribute(kAXPositionAttribute as CFString, from: item.element) else {
            return true
        }

        return abs(updatedPosition.x - position.x) <= 1 && abs(updatedPosition.y - position.y) <= 1
    }

    private static func copyElementAttribute(
        _ attribute: CFString,
        from element: AXUIElement
    ) -> AXUIElement? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success else {
            return nil
        }

        guard let value,
              CFGetTypeID(value) == AXUIElementGetTypeID() else {
            return nil
        }

        return (value as! AXUIElement)
    }

    private static func copyElementArrayAttribute(
        _ attribute: CFString,
        from element: AXUIElement
    ) -> [AXUIElement] {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success else {
            return []
        }

        return value as? [AXUIElement] ?? []
    }

    private static func copyStringAttribute(
        _ attribute: CFString,
        from element: AXUIElement
    ) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success else {
            return nil
        }

        return (value as? String)?.menuFolderTrimmed.nilIfEmpty
    }

    private static func pointAttribute(
        _ attribute: CFString,
        from element: AXUIElement
    ) -> CGPoint? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success,
              let value,
              CFGetTypeID(value) == AXValueGetTypeID() else {
            return nil
        }

        let axValue = value as! AXValue
        guard AXValueGetType(axValue) == .cgPoint else {
            return nil
        }

        var point = CGPoint.zero
        guard AXValueGetValue(axValue, .cgPoint, &point) else {
            return nil
        }
        return point
    }

    private static func sizeAttribute(
        _ attribute: CFString,
        from element: AXUIElement
    ) -> CGSize? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success,
              let value,
              CFGetTypeID(value) == AXValueGetTypeID() else {
            return nil
        }

        let axValue = value as! AXValue
        guard AXValueGetType(axValue) == .cgSize else {
            return nil
        }

        var size = CGSize.zero
        guard AXValueGetValue(axValue, .cgSize, &size) else {
            return nil
        }
        return size
    }

    private static func normalizedIDComponent(_ value: String) -> String {
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: ".-"))
        let transformed = value
            .lowercased()
            .unicodeScalars
            .map { allowedCharacters.contains($0) ? String($0) : "-" }
            .joined()
        let collapsed = transformed
            .split(separator: "-", omittingEmptySubsequences: true)
            .joined(separator: "-")
        return collapsed.isEmpty ? "unknown" : collapsed
    }
}

private struct AccessibilityMenuBarItem {
    let descriptor: MenuBarItemDescriptor
    let element: AXUIElement
}

private struct RawAccessibilityMenuBarItem {
    let descriptor: MenuBarItemDescriptor
    let element: AXUIElement
    let title: String
    let frame: CGRect
}

private struct StoredMenuBarItemOrigin: Codable {
    let x: CGFloat
    let y: CGFloat

    var point: CGPoint {
        CGPoint(x: x, y: y)
    }

    init(point: CGPoint) {
        x = point.x
        y = point.y
    }
}

private extension String {
    var menuFolderTrimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
