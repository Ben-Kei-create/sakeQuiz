import SwiftUI

struct CategoryListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(GameStore.self) private var store
    let categories: [QuizCategory]
    let onSelect: (QuizCategory) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(categories) { category in
                        Button { onSelect(category) } label: { row(category) }
                            .accessibilityIdentifier("category_\(category.rawValue)")
                    }
                } footer: {
                    if let weak = store.weakestCategory() {
                        Text("いま一番伸びしろがあるのは「\(weak.localizedName)」です。")
                    } else {
                        Text("5問以上解くと、苦手な分野をお知らせします。")
                    }
                }
            }
            .navigationTitle("分野別に挑戦")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("閉じる") { dismiss() } } }
        }
    }

    private func row(_ category: QuizCategory) -> some View {
        let stat = store.categoryAccuracy(category)
        let accuracy = stat.accuracyPercent.map { "\($0)%" } ?? "未挑戦"
        return HStack(spacing: 12) {
            Image(systemName: category.symbolName).foregroundStyle(NihonshuTheme.indigo)
                .frame(width: 32).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(category.localizedName).font(.headline).foregroundStyle(NihonshuTheme.sumi)
                Text("正答率 \(accuracy)・回答 \(stat.answered)問")
                    .font(.caption).foregroundStyle(NihonshuTheme.sumi.opacity(0.8))
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(NihonshuTheme.indigo).accessibilityHidden(true)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}
