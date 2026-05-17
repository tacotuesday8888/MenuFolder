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
        hasScreenRecordingPermission = CGPreflightScreenCaptureAccess()
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
}
