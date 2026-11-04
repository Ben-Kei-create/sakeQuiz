import SwiftUI

enum NihonshuTheme {
    /// 墨藍。主色。生成りとのコントラスト比は約13:1。
    static let indigo = Color(red: 0.122, green: 0.165, blue: 0.227)
    /// 墨。本文色。
    static let sumi = Color(red: 0.102, green: 0.118, blue: 0.157)
    /// 生成り。背景。
    static let kinari = Color(red: 0.969, green: 0.949, blue: 0.906)
    /// 淡い青磁。面や枠線。
    static let seiji = Color(red: 0.867, green: 0.910, blue: 0.878)
    /// 金茶。装飾（文字には使わない）。
    static let kincha = Color(red: 0.722, green: 0.592, blue: 0.353)
    /// 朱。誤答・注意。生成りとのコントラスト比は4.5:1以上。
    static let shu = Color(red: 0.690, green: 0.235, blue: 0.188)
    /// 若竹。正解。
    static let success = Color(red: 0.133, green: 0.388, blue: 0.267)
}

struct NihonshuBackdrop: View {
    var body: some View { NihonshuTheme.kinari.ignoresSafeArea() }
}

struct NihonshuPanel<Content: View>: View {
    var cornerRadius: CGFloat = 20
    @ViewBuilder let content: () -> Content
    var body: some View {
        content().padding(18)
            .background(.white.opacity(0.85), in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay { RoundedRectangle(cornerRadius: cornerRadius).stroke(NihonshuTheme.seiji, lineWidth: 1) }
    }
}

struct NihonshuChip: View {
    let title: String
    let color: Color
    var body: some View {
        Text(title).font(.caption.bold()).foregroundStyle(NihonshuTheme.sumi)
            .padding(.horizontal, 13).padding(.vertical, 8)
            .background(color.opacity(0.2), in: Capsule())
    }
}

struct NihonshuPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline.bold()).foregroundStyle(.white)
            .padding(.horizontal, 20).padding(.vertical, 18).frame(minHeight: 56)
            .background(NihonshuTheme.indigo, in: RoundedRectangle(cornerRadius: 20))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

struct NihonshuSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).foregroundStyle(NihonshuTheme.indigo)
            .padding(.horizontal, 18).padding(.vertical, 16).frame(minHeight: 52)
            .background(NihonshuTheme.seiji, in: RoundedRectangle(cornerRadius: 20))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct SakeMark: View {
    var body: some View {
        Canvas { context, size in
            let t = CGAffineTransform(scaleX: size.width / 120, y: size.height / 150)
            let kinari = NihonshuTheme.kinari
            // 徳利: 首と胴を円と角丸で構成
            let neck = Path(roundedRect: CGRect(x: 46, y: 10, width: 28, height: 40), cornerRadius: 8)
            context.fill(neck.applying(t), with: .color(kinari))
            let lip = Path(roundedRect: CGRect(x: 40, y: 6, width: 40, height: 10), cornerRadius: 5)
            context.fill(lip.applying(t), with: .color(kinari))
            let bowl = Path(ellipseIn: CGRect(x: 14, y: 40, width: 92, height: 92))
            context.fill(bowl.applying(t), with: .color(kinari))
            // 胴の帯（丸い印）
            let seal = Path(ellipseIn: CGRect(x: 40, y: 66, width: 40, height: 40))
            context.fill(seal.applying(t), with: .color(NihonshuTheme.shu))
            let band = Path(CGRect(x: 14, y: 84, width: 92, height: 3))
            context.fill(band.applying(t), with: .color(NihonshuTheme.kincha))
            
        }.accessibilityHidden(true)
    }
}
