# 日本酒雑学クイズ（sakeQuiz!）

SwiftUI製のiOSアプリ（iOS 17.0以降、iPhone専用）。ワイン版「wineryQuiz」の構成を引き継いだ、独立した日本酒クイズです。ワイン版は変更していません。

- 表示名：日本酒雑学クイズ ／ App Store名：sakeQuiz!（確定） ／ 作業名・ターゲット：`NihonshuQuiz`
- Bundle ID：`com.fumiaki.nihonshuQuiz`（新規。ワイン版の値は使用しない）／ SKU案：`nihonshuquiz-ios`
- Team：7R927F3U4V、自動署名、バージョン1.0.0 (1)

## 開く
`NihonshuQuiz.xcodeproj` を開き、`NihonshuQuiz` schemeを実行。`project.yml` から `xcodegen generate` で再生成できます。
**`WineQuiz` や旧 `sakeQuiz` のプロジェクトは開かない**（Archive前に、Xcodeのタイトルバーのパスが `/Applications/sakeQuiz/NihonshuQuiz.xcodeproj` であることを確認）。

## 機能
通常10問（初級25秒・中級20秒・上級18秒）、分野別の出題と分野別正答率、今日の1問、復習（間違えた回数の多い順）、連続正解の記録、結果の解答履歴とシェア、設定（効果音・触覚・制限時間をなくす・成績リセット）。データは端末内（UserDefaults）のみ。

## 問題
271問（国税庁と日本酒造組合中央会の公開資料）。出典と確認日は [Documentation/QUESTION_VERIFICATION.md](Documentation/QUESTION_VERIFICATION.md) と [sources.json](Documentation/sources.json)。`Tools/questions_part*.py` を編集して `python3 Tools/build_questions.py` で再生成します。
**現状の限界**：酒類総合研究所の本文は未照合、ペアリングは日本酒造組合中央会の4タイプの紹介に限る。詳細は [Submission/STATUS.md](Submission/STATUS.md)。

## 広告
AdMobバナーのみ。非パーソナライズ（npa=1）、Publisher First-Party ID無効、ATTなし。UMPで同意を取得し、同意できない場合も広告なしでクイズを利用できます。
**現在はDebug・Releaseともに、Google公式のテストID**（日本酒版のAdMobアプリID／広告ユニットIDは未発行）。ワイン版のIDは使っていません。

お酒は20歳になってから。

© 2026 Fumiaki Mogi. All rights reserved.
