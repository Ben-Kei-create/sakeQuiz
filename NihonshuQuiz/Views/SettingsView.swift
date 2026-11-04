import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(GameStore.self) private var store
    @Environment(AdsPrivacyController.self) private var adsPrivacy

    @AppStorage(SoundPlayer.soundEnabledKey) private var soundEnabled = true
    @AppStorage(SoundPlayer.hapticsEnabledKey) private var hapticsEnabled = true
    @AppStorage(QuizTimer.disabledKey) private var timerDisabled = false
    @State private var showResetConfirmation = false

    private var versionText: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("サウンド") {
                    Toggle("効果音", isOn: $soundEnabled)
                    Toggle("触覚フィードバック", isOn: $hapticsEnabled)
                }

                Section {
                    Toggle("制限時間をなくす", isOn: $timerDisabled)
                } header: {
                    Text("クイズ")
                } footer: {
                    Text("オンにすると、時間切れなしで考えられます。")
                }

                Section("成績") {
                    Button("成績をリセット", role: .destructive) {
                        showResetConfirmation = true
                    }
                }

                if adsPrivacy.isPrivacyOptionsRequired {
                    Section("プライバシー") {
                        Button("広告のプライバシー設定") {
                            Task { await adsPrivacy.presentPrivacyOptions() }
                        }
                    }
                }
                Section("アプリについて") {
                    LabeledContent("バージョン", value: versionText)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("バージョン")
                        .accessibilityValue(versionText)
                        .accessibilityIdentifier("app_version")
                    NavigationLink("プライバシーポリシー") { PrivacyView() }
                    Text("お酒は20歳になってから。飲酒運転は法律で禁止されています。")
                        .font(.caption)

                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                }
            }
            .alert("広告のプライバシー設定", isPresented: Binding(
                get: { adsPrivacy.privacyOptionsError != nil },
                set: { if !$0 { adsPrivacy.privacyOptionsError = nil } }
            )) {
                Button("閉じる") { adsPrivacy.privacyOptionsError = nil }
            } message: {
                Text(adsPrivacy.privacyOptionsError ?? "")
            }
            .confirmationDialog("ハイスコア・累計成績・分野別の正答率・間違えた回数・連続正解・復習リスト・今日の挑戦状況を消去します。", isPresented: $showResetConfirmation, titleVisibility: .visible) {
                Button("リセットする", role: .destructive) {
                    store.resetStats()
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(GameStore())
        .environment(AdsPrivacyController())
}

struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("日本酒雑学クイズ").font(.title2.bold())
                Text("成績・分野別の正答率・間違えた回数・復習対象・今日の挑戦状況・効果音と触覚の設定は端末内に保存します。アプリ独自のサーバーへの送信やアカウント登録はありません。成績は設定からリセットできます。")
                Text("広告にはGoogle Mobile Ads SDKを利用しています。広告のパーソナライズを無効にし、非パーソナライズ広告を要求します。広告用の追跡許可（ATT）は要求しません。SDKは広告の取得や不正防止のため、IPアドレス、端末情報、診断情報などをGoogleへ送信することがあります。")
                Text("広告の取得前にGoogle User Messaging Platformで同意状況を確認し、必要な選択画面を表示します。選択の変更が必要な場合は、設定の「広告のプライバシー設定」から行えます。")
                Link("公開プライバシーポリシー", destination: URL(string: "https://www.givetex.org/apps/nihonshuquiz/privacy/")!)
                Link("Googleのプライバシーポリシー", destination: URL(string: "https://policies.google.com/privacy")!)
                Text("結果のシェアは操作したときだけ共有画面を開きます。送信先と送信内容は共有画面で選択できます。出典リンクは外部サイトを開きます。")
                Text("最終更新：2026年11月3日").font(.caption)
            }.padding(24)
        }.navigationTitle("プライバシー").navigationBarTitleDisplayMode(.inline)
    }
}
