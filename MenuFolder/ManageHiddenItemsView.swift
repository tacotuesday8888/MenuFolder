import SwiftUI

struct ManageHiddenItemsView: View {
    @ObservedObject var hidingController: MenuBarHidingController
    @ObservedObject var hiddenItemsStore: HiddenItemsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            List(hidingController.detectedItems) { item in
                Toggle(isOn: binding(for: item.id)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.displayName)
                            .font(.body)
                        Text(item.ownerName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(minHeight: 180)

            HStack {
                Button("Refresh") {
                    hidingController.refreshDetectedItems()
                }

                Spacer()

                Text("Phase 1 placeholder list")
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

    private func binding(for itemID: String) -> Binding<Bool> {
        Binding {
            hiddenItemsStore.isHidden(itemID)
        } set: { isHidden in
            hiddenItemsStore.setHidden(isHidden, for: itemID)
            hidingController.applyHiddenState()
        }
    }
}
