import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppModel.self) private var model
    @Environment(AdConsent.self) private var consent
    @AppStorage(Feedback.hapticsKey) private var haptics = true
    @AppStorage(Furigana.enabledKey) private var furigana = true
    @Environment(ReminderCenter.self) private var reminder
    @State private var confirmReset = false

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
    }

    var body: some View {
        NavigationStack {
            List {
                Section("読みやすさ") {
                    Toggle("ふりがな", isOn: $furigana)
                }
                reminderSection
                Section("手応え") {
                    Toggle("触覚", isOn: $haptics)
                }
                Section("記録") {
                    Button("記録を消す", role: .destructive) { confirmReset = true }
                        .accessibilityIdentifier("reset_button")
                }
                if consent.offersChoices {
                    Section("広告") {
                        Button("広告のプライバシー設定") { Task { await consent.reopenChoices() } }
                    }
                }
                Section("この帳面について") {
                    LabeledContent("版", value: version)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("版")
                        .accessibilityValue(version)
                        .accessibilityIdentifier("app_version")
                    NavigationLink("プライバシー") { PrivacyView() }
                    NavigationLink("ライセンス") { LicensesView() }
                    Text("お酒は二十歳になってから。飲酒運転は法律で禁じられている。")
                        .font(.footnote)
                }
            }
            .font(.mincho(16))
            .scrollContentBackground(.hidden)
            .background(Theme.washi)
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("閉じる") { dismiss() } } }
            .confirmationDialog("仕込みの記録、復習、印を、すべて消します。", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("消す", role: .destructive) { model.store.reset() }
            }
            .alert("広告のプライバシー設定", isPresented: Binding(
                get: { consent.alertMessage != nil },
                set: { if !$0 { consent.alertMessage = nil } }
            )) {
                Button("閉じる") { consent.alertMessage = nil }
            } message: { Text(consent.alertMessage ?? "") }
        }
    }
}

extension SettingsView {
    @ViewBuilder
    fileprivate var reminderSection: some View {
        Section {
            Toggle("毎日のお知らせ", isOn: Binding(
                get: { reminder.isEnabled },
                set: { on in
                    Task {
                        if on { await reminder.enable() } else { await reminder.disable() }
                        await reminder.reschedule(store: model.store, now: model.now)
                    }
                }))
                .accessibilityIdentifier("reminder_toggle")
            if reminder.isEnabled {
                DatePicker("時刻", selection: Binding(
                    get: { Calendar.current.date(bySettingHour: reminder.hour, minute: reminder.minute, second: 0, of: .now) ?? .now },
                    set: { d in
                        let c = Calendar.current.dateComponents([.hour, .minute], from: d)
                        reminder.setTime(hour: c.hour ?? 19, minute: c.minute ?? 0)
                        Task { await reminder.reschedule(store: model.store, now: model.now) }
                    }), displayedComponents: .hourAndMinute)
            }
            if reminder.authorization == .denied {
                Text("端末の設定で、通知が許可されていません。")
                    .font(.footnote)
                Button("端末の設定を開く") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                }
            }
        } header: {
            Text("お知らせ")
        } footer: {
            Text("決めた時刻に、端末の中から、1日1回だけ知らせる。今日の仕込みを終えた日は、知らせない。")
        }
    }
}

struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacing.m) {
                Text("プライバシー").font(.mincho(24, bold: true, relativeTo: .title2))
                Text("仕込みの記録、復習、印、触覚の設定は、この端末の中にだけ保存する。独自のサーバーへの送信や、登録は、ない。記録は、設定から消せる。")
                Text("広告には、Google Mobile Ads SDKを使う。広告のパーソナライズは無効で、広告用の追跡許可は求めない。SDKは、広告の取得や不正の防止のため、IPアドレスや端末の情報などをGoogleへ送ることがある。")
                Text("広告を取得する前に、Google User Messaging Platformで同意の状況を確かめ、必要な選択画面を出す。")
                Link("公開のプライバシーポリシー", destination: URL(string: "https://www.givetex.org/apps/kuragoyomi/privacy/")!)
                Link("Googleのプライバシーポリシー", destination: URL(string: "https://policies.google.com/privacy")!)
                Text("毎日のお知らせは、端末の中だけで動くローカル通知で、サーバーへは何も送らない。許可は、設定から取り消せる。")
                Text("読み上げは、端末の標準の音声を使う。出典のリンクは、外部のサイトを開く。")
            }
            .font(.mincho(16))
            .foregroundStyle(Theme.sumi)
            .padding(Theme.spacing.m)
        }
        .background(Theme.washi)
        .navigationTitle("プライバシー")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LicensesView: View {
    private let files = [("Shippori Mincho", "ShipporiMincho-OFL"), ("Source Serif 4", "SourceSerif4-OFL")]

    var body: some View {
        List {
            ForEach(files, id: \.1) { name, file in
                Section(name) {
                    Text(text(file)).font(.system(size: 12, design: .monospaced))
                }
            }
        }
        .navigationTitle("ライセンス")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func text(_ file: String) -> String {
        Bundle.main.url(forResource: file, withExtension: "txt").flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? "ライセンス文を読み込めません。"
    }
}
