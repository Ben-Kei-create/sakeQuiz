import SwiftUI

struct ResultView: View {
    let session: QuizSession
    let restart: () -> Void
    let close: () -> Void
    var canRestart: Bool = true
    var isNewHighScore: Bool = false

    private var percentage: Int {
        guard !session.questions.isEmpty else {
            return 0
        }

        return Int((Double(session.score) / Double(session.questions.count) * 100).rounded())
    }

    private var shareText: String {
        "日本酒雑学クイズで \(session.score) / \(session.questions.count) 問正解！（正答率 \(percentage)%）🍶 #日本酒雑学クイズ"
    }

    private var weakNote: some View {
        let wrong = session.answerHistory.filter { !$0.isCorrect }.count
        return Text(wrong == 0 ? "全問正解です。" : "間違えた\(wrong)問は「復習」に追加されました。")
            .font(.subheadline).foregroundStyle(NihonshuTheme.sumi.opacity(0.8))
    }

    var body: some View {
        ZStack {
            NihonshuBackdrop()

            ScrollView {
                VStack(spacing: 22) {
                    NihonshuPanel(cornerRadius: 28) {
                        VStack(spacing: 10) {
                            Text("\(session.score) / \(session.questions.count)")
                                .font(.system(.largeTitle, design: .rounded, weight: .black))
                                .minimumScaleFactor(0.6).lineLimit(1)
                                .foregroundStyle(NihonshuTheme.sumi)

                            Text("正答率 \(percentage)%")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(NihonshuTheme.success)

                            if isNewHighScore {
                                Label("ハイスコア更新！", systemImage: "trophy.fill")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(NihonshuTheme.indigo)
                            }

                            weakNote
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }

                    VStack(spacing: 12) {
                        if canRestart {
                            Button(action: restart) {
                                Label("もう一度挑戦", systemImage: "arrow.clockwise")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(NihonshuPrimaryButtonStyle())
                        }

                        ShareLink(item: shareText) {
                            Label("結果をシェア", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(NihonshuSecondaryButtonStyle())

                        Button(action: close) {
                            Label("ホームに戻る", systemImage: "house.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(NihonshuSecondaryButtonStyle())
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("解答履歴")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(NihonshuTheme.sumi)

                        ForEach(session.answerHistory) { answer in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: answer.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(answer.isCorrect ? NihonshuTheme.success : NihonshuTheme.shu)
                                    .accessibilityLabel(answer.isCorrect ? "正解" : "不正解")
                                    .padding(.top, 2)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(answer.question.question)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(NihonshuTheme.sumi)
                                    Text("あなたの答え: \(answer.selectedText)")
                                        .font(.caption)
                                        .foregroundStyle(NihonshuTheme.sumi.opacity(0.75))
                                    Text("正解: \(answer.question.correctChoice)").font(.caption.bold())
                                    Text(answer.question.trivia).font(.caption)
                                    if let title = answer.question.sourceTitle, let address = answer.question.sourceURL,
                                       let url = URL(string: address) {
                                        Link(title, destination: url).font(.caption)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .accessibilityElement(children: .contain)
                        }
                    }
                    .padding(18)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("結果")
        .navigationBarBackButtonHidden()
    }
}
