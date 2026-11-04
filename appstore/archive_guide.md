# Archive とアップロードの手順（本人が操作。署名・提出は、AIが行わない）

## 0. 確認
- 開くプロジェクトの場所：`/Applications/sakeQuiz/NihonshuQuiz.xcodeproj`（`WineQuiz` や旧 `sakeQuiz` を開かない。Xcodeのタイトルバーで確認）
- scheme：`NihonshuQuiz`、版：1.0.0、ビルド：1（`project.yml`）。Bundle ID：`com.fumiaki.kuragoyomi`
- 先に Developer ポータルで Bundle ID を登録し、App Store Connect にレコードを作ってある。
- 事前に、`git status` が空、`main` が最新（`git pull`）。

## 1. 自分で確認するテスト（任意だが推奨）
```bash
xcodebuild test -project NihonshuQuiz.xcodeproj -scheme NihonshuQuiz -destination 'platform=iOS Simulator,name=iPhone 17'
```
（機種名は、手元のシミュレーターに合わせる。`xcrun simctl list devices available` で確認）

## 2. Archive（Xcode の画面）
1. Xcode で上のプロジェクトを開く。
2. 実行先を **Any iOS Device (arm64)** にする。
3. メニュー Product → Archive。
4. Organizer が開いたら、Distribute App → App Store Connect → Upload → 自動署名（Automatic）→ Upload。

## 3. アップロード後
1. App Store Connect → TestFlight で、ビルドの処理（数分〜）を待つ。
2. 輸出コンプライアンスの質問は「免除」（`Info.plist` に `ITSAppUsesNonExemptEncryption = false`）。
3. TestFlight：外部テスト → グループ → 公開リンク（最初のビルドは、ベータ審査）。
4. 審査に出すときは、バージョン 1.0.0 のページで、このビルドを選ぶ。

## 4. 出荷ビルドの確認（Archive前の最終チェック）
- Release の広告：アプリID `…~4918623404`、バナー `…/6886486209`（`project.yml`、`BannerSlot.swift`）。
- Release に、`-SCREENSHOT_MODE` 等の撮影用の処理が入っていない（DEBUG限定。Releaseでは、コンパイルされない）。
- 本番の広告を、自分の端末で、タップしない（無効なクリックになる）。確認はテストIDのDebugで行う。
