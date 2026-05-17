import SwiftUI

struct PermissionsWelcomeView: View {
    @ObservedObject var permissionsManager: PermissionsManager
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            permissionRows

            HStack {
                Button("Refresh") {
                    permissionsManager.refresh()
                }

                Spacer()

                Button(permissionsManager.hasRequiredPermissions ? "Continue" : "Continue Anyway") {
                    onContinue()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 500)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "folder")
                .font(.system(size: 34, weight: .regular))
                .foregroundStyle(Color.accentColor)

            Text("Welcome to MenuFolder")
                .font(.title2.weight(.semibold))

            Text("MenuFolder needs Accessibility permission to organize menu bar icons; Screen Recording may improve detection on some macOS versions.")
                .foregroundStyle(.secondary)
        }
    }

    private var permissionRows: some View {
        VStack(spacing: 12) {
            PermissionRow(
                title: "Accessibility",
                message: "Accessibility lets MenuFolder move the menu bar icons you choose.",
                isGranted: permissionsManager.hasAccessibilityPermission,
                buttonTitle: "Open Accessibility Settings",
                action: permissionsManager.openAccessibilitySettings
            )

            PermissionRow(
                title: "Screen Recording",
                message: "Screen Recording helps MenuFolder read screen metadata when macOS requires it.",
                isGranted: permissionsManager.hasScreenRecordingPermission,
                buttonTitle: "Open Screen Recording Settings",
                action: permissionsManager.openScreenRecordingSettings
            )
        }
    }
}

private struct PermissionRow: View {
    let title: String
    let message: String
    let isGranted: Bool
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(isGranted ? .green : .orange)
                .font(.title3)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 16)

            Button(buttonTitle, action: action)
                .disabled(isGranted)
        }
        .padding(12)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
    }
}
