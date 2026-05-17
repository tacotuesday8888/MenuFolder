import AppKit
import ApplicationServices
import Combine
import CoreGraphics

final class PermissionsManager: ObservableObject {
    @Published private(set) var hasAccessibilityPermission = false
    @Published private(set) var hasScreenRecordingPermission = false

    var hasRequiredPermissions: Bool {
        hasAccessibilityPermission && hasScreenRecordingPermission
    }

    init() {
        refresh()
    }

    func refresh() {
        hasAccessibilityPermission = AXIsProcessTrusted()
        hasScreenRecordingPermission = Self.hasScreenRecordingAccess()
    }

    func openAccessibilitySettings() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
        openSystemSettings(
            primary: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        )
    }

    func openScreenRecordingSettings() {
        _ = CGRequestScreenCaptureAccess()
        openSystemSettings(
            primary: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
        )
    }

    private func openSystemSettings(primary: String) {
        if let url = URL(string: primary), NSWorkspace.shared.open(url) {
            return
        }

        if let fallback = URL(string: "x-apple.systempreferences:com.apple.preference.security") {
            NSWorkspace.shared.open(fallback)
        }
    }

    private static func hasScreenRecordingAccess() -> Bool {
        if CGPreflightScreenCaptureAccess() {
            return true
        }

        let options = CGWindowListOption(arrayLiteral: .optionOnScreenOnly, .excludeDesktopElements)
        guard let windowInfoList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return false
        }

        let currentProcessIdentifier = Int(ProcessInfo.processInfo.processIdentifier)
        return windowInfoList.contains { windowInfo in
            guard let ownerProcessIdentifier = windowInfo[kCGWindowOwnerPID as String] as? Int,
                  ownerProcessIdentifier != currentProcessIdentifier,
                  let layer = windowInfo[kCGWindowLayer as String] as? Int,
                  layer == 0,
                  let windowName = windowInfo[kCGWindowName as String] as? String else {
                return false
            }

            return !windowName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}
