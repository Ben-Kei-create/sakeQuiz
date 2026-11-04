import SwiftUI

struct UnavailableView: View {
    let message: String

    var body: some View {
        ZStack {
            NihonshuBackdrop()

            NihonshuPanel {
                ContentUnavailableView(
                    "読み込めませんでした",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
                .foregroundStyle(NihonshuTheme.sumi)
            }
            .padding()
        }
    }
}
