import SwiftUI

/// 蔵印帳。地理的表示（GI）の産地を、問いに正解すると1つずつ印が押される。
struct SealBookView: View {
    let library: ContentLibrary
    @Environment(AppModel.self) private var model
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: Theme.spacing.m)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacing.m) {
                Text("蔵印帳")
                    .font(.mincho(34, bold: true, relativeTo: .largeTitle))
                    .accessibilityAddTraits(.isHeader)
                Text("\(model.store.state.seals.count)／\(library.seals.count) 押した")
                    .font(.mincho(15, relativeTo: .subheadline))
                LazyVGrid(columns: columns, spacing: Theme.spacing.m) {
                    ForEach(library.seals) { seal in card(seal) }
                }
                Text("産地の名は、国税庁が指定した地理的表示による。仕込みの中の問いに正解すると、印が押される。")
                    .font(.mincho(13, relativeTo: .footnote))
                    .foregroundStyle(Theme.sumi.opacity(0.8))
            }
            .foregroundStyle(Theme.sumi)
            .padding(Theme.spacing.m)
        }
        .background(Theme.washi)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func card(_ seal: SealDefinition) -> some View {
        let date = model.store.state.seals[seal.id]
        return LinedPage {
            VStack(spacing: Theme.spacing.s) {
                if date != nil {
                    Seal(text: seal.name, size: 84)
                    Text(seal.place).font(.mincho(13, relativeTo: .caption))
                    Text(seal.note).font(.mincho(12, relativeTo: .caption2)).multilineTextAlignment(.center)
                } else {
                    Circle()
                        .strokeBorder(Theme.sumi.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                        .frame(width: 84, height: 84)
                        .overlay { Text("未").font(.mincho(22, bold: true, relativeTo: .title2)).foregroundStyle(Theme.sumi.opacity(0.5)) }
                    Text("まだ、押していない").font(.mincho(13, relativeTo: .caption))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(date != nil ? "\(seal.name)、\(seal.place)、押した" : "未、まだ押していない")
    }
}
