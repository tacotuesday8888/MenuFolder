import SwiftUI

struct ManageHiddenItemsView: View {
    @ObservedObject var hidingController: MenuBarHidingController
    @ObservedObject var hiddenItemsStore: HiddenItemsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            Group {
                if hidingController.detectedItems.isEmpty {
                    emptyState
                } else {
                    List(hidingController.detectedItems) { item in
                        Toggle(isOn: binding(for: item.id)) {
                            HStack(spacing: 8) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.displayName)
                                        .font(.body)
                                    Text(item.ownerName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                if let failureMessage = hidingController.moveFailuresByItemID[item.id] {
                                    Spacer(minLength: 8)
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.orange)
                                        .help(failureMessage)
                                }
                            }
                        }
                    }
                }
            }
            .frame(minHeight: 180)

            HStack {
                Button {
                    hidingController.refreshDetectedItems()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }

                Spacer()

                Text(itemCountText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(width: 420, height: 340)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Manage Hidden Items")
                .font(.title3.weight(.semibold))
            Text("Choose which menu bar items MenuFolder should hide.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "menubar.rectangle")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("No menu bar items detected")
                .font(.headline)
            Text("Check Screen Recording permission, then refresh.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var itemCountText: String {
        let count = hidingController.detectedItems.count
        return count == 1 ? "1 item detected" : "\(count) items detected"
    }

    private func binding(for itemID: String) -> Binding<Bool> {
        Binding {
            hiddenItemsStore.isHidden(itemID)
        } set: { isHidden in
            hiddenItemsStore.setHidden(isHidden, for: itemID)
            hidingController.applyHiddenState()
        }
    }
}
