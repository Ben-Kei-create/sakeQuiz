# 蔵ごよみ

日本酒を、一日ひとつ学ぶ、無料の独学の仕込み帳。SwiftUI製のiOSアプリ（iOS 17.0以降、iPhone専用）。約60日の「仕込み暦」で、1日1回、その日の工程の読み物と確認問題に取り組む。

- 表示名：蔵ごよみ ／ プロジェクト・ターゲット名：`NihonshuQuiz`（内部名。画面には出ない） ／ Bundle ID：`com.fumiaki.kuragoyomi` ／ SKU：`kuragoyomi-ios-001`
- Team：7R927F3U4V、自動署名、版 1.0.0 (1)
- ワイン版（同型のため4.3でリジェクト）とは別。コードは流用せず、新規に実装している（広告まわりを除く。下記）。

## 開く
`NihonshuQuiz.xcodeproj` を開き、`NihonshuQuiz` schemeを実行。`project.yml` から `xcodegen generate` で再生成できる。
**`WineQuiz` や旧 `sakeQuiz` のプロジェクトは開かない**（Archive前に、パスが `/Applications/sakeQuiz/NihonshuQuiz.xcodeproj` であることを確認）。

## 構成
- 仕込み暦（1日1回、60日）／ふりがな（`ruby.json`）／毎日のお知らせ（端末内のローカル通知、任意）／復習（間違えた問題を1・3・7日後に出し直す）／蔵印帳（地理的表示8つ）／設定。読み上げは端末標準の音声。
- 設計：[docs/design_brief.md](docs/design_brief.md)、診断：[docs/existing_app_diagnosis.md](docs/existing_app_diagnosis.md)、リサーチ：[docs/research_memo.md](docs/research_memo.md)。
- データは端末内（UserDefaults）のみ。アカウント・課金・独自サーバーなし。

## 内容と出典
読み物60日分（`Tools/lessons_part*.py`）と問題271問（`Tools/questions_part*.py`）。`python3 Tools/build_questions.py && python3 Tools/build_lessons.py` で `Resources/` のJSONを生成する。問題IDは並び順から付くので、追記のみ（入れ替えない）。
出典は国税庁と日本酒造組合中央会の公開資料。確認記録：[Documentation/QUESTION_VERIFICATION.md](Documentation/QUESTION_VERIFICATION.md)、[sources.json](Documentation/sources.json)。新しい漢字を足したら `Tools/subset_fonts.sh` でフォントを作り直す（足りない文字は、テストが検出する）。

## 広告
AdMobバナーのみ。Debugは、Google公式のテストID。Releaseは、蔵ごよみ専用のID（AdMobのアプリ名 `kuragoyomi_bar`）。ワイン版のIDは使わない。非パーソナライズ、ATTなし、UMPで同意を取得。広告まわり（`AdConsent.swift`、`BannerSlot.swift`）は、ワイン版から書き直した。ワイン版とのSwiftコードの一致率は約21％（`Tools/measure_overlap.py`）。

お酒は二十歳になってから。

フォント：Shippori Mincho、Source Serif 4（SIL Open Font License。`Documentation/Licenses/`）。
© 2026 Fumiaki Mogi. All rights reserved.
