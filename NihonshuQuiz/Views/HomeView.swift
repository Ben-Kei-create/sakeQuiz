import SwiftUI

struct HomeView: View {
    let questionCount: Int
    let categories: [QuizCategory]
    let reviewCount: Int
    let startQuiz: () -> Void
    let startReview: () -> Void
    let startDaily: () -> Void
    let startCategory: (QuizCategory) -> Void
    @Environment(GameStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var showSettings = false
    @State private var showCategories = false
    @State private var today = Date.now
    private var dailyCompleted: Bool { store.isDailyCompleted(on: today) }

    var body: some View {
        ZStack(alignment: .top) {
            NihonshuBackdrop()
            NihonshuTheme.indigo.frame(height: 240).accessibilityHidden(true)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    hero
                    VStack(alignment: .leading, spacing: 24) {
                        stats
                        VStack(alignment: .leading, spacing: 8) {
                            Text("次の10問に挑戦").font(.largeTitle.bold())
                            Text("米も水も蔵の話も、クイズで楽しく。")
                                .font(.subheadline).foregroundStyle(NihonshuTheme.sumi.opacity(0.8))
                        }
                        Button(action: startQuiz) {
                            HStack { Text("クイズをはじめる"); Spacer(); Image(systemName: "chevron.right") }
                                .frame(maxWidth: .infinity)
                        }.buttonStyle(NihonshuPrimaryButtonStyle()).accessibilityIdentifier("start_quiz_button")
                        VStack(spacing: 0) {
                            Divider()
                            menuRow(title: dailyCompleted ? "今日の1問（挑戦済み）" : "今日の1問",
                                    subtitle: dailyCompleted ? "また明日、新しい知識に出会おう。" : "毎日1問、日本酒の知識を深めよう。",
                                    symbol: dailyCompleted ? "checkmark" : "text.book.closed",
                                    enabled: !dailyCompleted, action: startDaily)
                                .accessibilityIdentifier("daily_quiz_button")
                            Divider()
                            menuRow(title: "分野別に挑戦",
                                    subtitle: "分野ごとの正答率もわかります。",
                                    symbol: "square.grid.2x2", enabled: true) { showCategories = true }
                                .accessibilityIdentifier("category_menu_button")
                            Divider()
                            menuRow(title: reviewCount > 0 ? "間違えた問題を復習（\(reviewCount)問）" : "間違えた問題を復習",
                                    subtitle: reviewCount > 0 ? "苦手な問題をもう一度解こう。" : "間違えた問題がここに集まります。",
                                    symbol: "arrow.counterclockwise", enabled: reviewCount > 0, action: startReview)
                                .accessibilityIdentifier("review_quiz_button")
                            Divider()
                        }
                        Text("全\(questionCount)問・\(categories.count)分野・初級〜上級・1回10問")
                            .font(.caption).foregroundStyle(NihonshuTheme.sumi.opacity(0.8))
                            .frame(maxWidth: .infinity)
                        Text("お酒は20歳になってから。")
                            .font(.caption).foregroundStyle(NihonshuTheme.sumi.opacity(0.8))
                            .frame(maxWidth: .infinity)
                    }
                    .padding(24).background(NihonshuTheme.kinari)
                }
            }.scrollIndicators(.hidden)
        }
        .foregroundStyle(NihonshuTheme.sumi)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showCategories) {
            CategoryListView(categories: categories, onSelect: { category in
                showCategories = false
                startCategory(category)
            })
        }
        .onChange(of: scenePhase) { _, phase in if phase == .active { today = .now } }
        .onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) { today = $0 }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("知るほど、おいしい。")
                    .font(.subheadline.weight(.semibold)).tracking(2)
                Spacer()
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape").font(.title3)
                        .foregroundStyle(NihonshuTheme.sumi).frame(width: 44, height: 44)
                        .background(NihonshuTheme.kinari, in: Circle())
                }.accessibilityLabel("設定").accessibilityIdentifier("settings_button")
            }
            Text("日本酒雑学クイズ")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Text("ひとくちの知識が、\n次の一杯を豊かに。")
                    .font(.subheadline).lineSpacing(5)
                Spacer()
                SakeMark().frame(width: 94, height: 118)
            }
        }.foregroundStyle(NihonshuTheme.kinari).padding(24)
            .background(NihonshuTheme.indigo)
    }

    private var stats: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16))
            : AnyLayout(HStackLayout(spacing: 16))
        return layout {
            stat("ハイスコア", value: "\(store.highScore)/10", symbol: "trophy.fill")
            if !typeSize.isAccessibilitySize { Divider() }
            stat("累計正答率", value: store.accuracyPercent.map { "\($0)%" } ?? "—", symbol: "chart.bar.fill")
            if !typeSize.isAccessibilitySize { Divider() }
            stat("連続正解", value: "\(store.currentStreak)", symbol: "flame.fill")
        }
        .fixedSize(horizontal: false, vertical: true).padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }

    private func stat(_ title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text(title).foregroundStyle(NihonshuTheme.sumi.opacity(0.75))
            } icon: { Image(systemName: symbol).foregroundStyle(NihonshuTheme.kincha) }.font(.caption)
            Text(value).font(.system(.title, design: .rounded, weight: .bold)).monospacedDigit()
                .minimumScaleFactor(0.6).lineLimit(1)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private func menuRow(title: String, subtitle: String, symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol).font(.title3).foregroundStyle(NihonshuTheme.indigo)
                    .frame(minWidth: 44, minHeight: 44).background(NihonshuTheme.seiji, in: Circle()).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 6) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.caption).foregroundStyle(NihonshuTheme.sumi.opacity(0.8))
                }.frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right").foregroundStyle(NihonshuTheme.indigo).accessibilityHidden(true)
            }.accessibilityElement(children: .combine).padding(.vertical, 20).contentShape(Rectangle())
        }.buttonStyle(.plain).disabled(!enabled).opacity(enabled ? 1 : 0.65)
    }
}
