# 申請準備状況（未完成）

2026-11-04。ブラウザ操作・管理画面入力・Archive・アップロード・審査送信は実施していません。

## 状況
ワイン版が4.3(a)(b)・4.2.6でリジェクトされたため、同型の本アプリを作り直した（`docs/existing_app_diagnosis.md`、`docs/design_brief.md`）。名前は「蔵ごよみ」。

## 完了（シミュレーターで確認）
- 仕込み暦60日分の読み物、問題271問（225問を暦に紐づけ）、5つの画面、間隔反復の復習、蔵印帳8つ。
- 単体33件・UI3件が成功（iPhone 18 Pro、iOS 27系）。

## 完成を妨げる項目
| 項目 | 必要な対応 |
|---|---|
| 4.3への答え | TestFlightの実績（友人5人以上、意見と反映を `docs/testflight_feedback.md` に記録）。返信文は `docs/review_reply_draft.md` に、本人が確認して入力 |
| ワイン版とのコード共有（質問7） | 広告まわりを書き直し済み（`AdConsent.swift`、`BannerSlot.swift`）。Swift 1,251行のうち、ワイン版と一致するのは約21％（`Tools/measure_overlap.py`。import・括弧・SwiftUIの標準的な修飾子・広告SDKの必須のAPI呼び出しなど、定型の行を含む）。ワイン版のレコードの削除は本人 |
| 公開ページ | `https://www.givetex.org/apps/kuragoyomi/privacy/` は未公開。申請前に本番で公開 |
| AdMob | 日本酒版のアプリ・広告ユニットIDの発行。確定後、実装前に確認して差し替え |
| 実機確認 | [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md)。iOS 17は未確認（シミュレーターなし） |
| アクセシビリティ | 実機のVoiceOver確認が済むまで宣言しない |
| App Store Connect | 名前「蔵ごよみ」の使用可否を本人が確認。先にBundle IDを確定してからレコードを作る。年齢区分（飲酒関連）を申告 |
| スクリーンショット | 6.3インチ（1206×2622）を、実アプリ画面から作成（テスト広告を写さない） |
| 通知（任意） | 未実装。入れる場合は、3日目以降に1回だけ依頼 |

出典の限界：酒類総合研究所・都道府県の酒造組合・大学の本文は未照合。★1〜3のレビュー確認も未了（`docs/research_memo.md`）。
