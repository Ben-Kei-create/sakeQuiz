import SwiftUI
import UIKit

/// 問題を1問ずつ出す。時間の制限はない。答えたあとに解説と出典を見せ、「次へ」は画面の下に固定する。
struct QuestionFlowView: View {
    let questions: [QuizQuestion]
    let finishTitle: String
    /// 答えを記録し、知らせたいことがあれば文を返す（例：印を押した）。
    let onAnswer: (QuizQuestion, Bool) -> String?
    let onFinish: () -> Void

    @State private var index = 0
    @State private var chosen: Int?
    @State private var notice: String?

    private var question: QuizQuestion { questions[index] }
    private var isLast: Bool { index == questions.count - 1 }
    private let numerals = ["一", "二", "三", "四"]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.spacing.m) {
                    Color.clear.frame(height: 0).id("top")
                    Text("問 \(index + 1)／\(questions.count)")
                        .font(.mincho(14, relativeTo: .footnote))
                        .foregroundStyle(Theme.sumi.opacity(0.8))
                    RubyText(text: question.question, size: 21, bold: true, style: .title3)
                        .accessibilityAddTraits(.isHeader)
                    VStack(spacing: Theme.spacing.s) {
                        ForEach(question.choices.indices, id: \.self) { i in choiceRow(i) }
                    }
                    if let chosen { explanation(correct: chosen == question.correctAnswerIndex) }
                }
                .padding(Theme.spacing.m)
            }
            .onChange(of: index) { _, _ in proxy.scrollTo("top", anchor: .top) }
        }
        .background(Theme.washi)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if chosen != nil {
                Button(action: advance) { Text(isLast ? finishTitle : "次へ") }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, Theme.spacing.m)
                    .padding(.vertical, Theme.spacing.s)
                    .background(Theme.washi)
                    .accessibilityIdentifier("next_button")
            }
        }
    }

    private func choiceRow(_ i: Int) -> some View {
        let answered = chosen != nil
        let isCorrect = i == question.correctAnswerIndex
        let isChosen = i == chosen
        let mark = !answered ? "" : isCorrect ? "正解" : isChosen ? "あなたの答え" : ""
        return Button {
            guard chosen == nil else { return }
            chosen = i
            let correct = i == question.correctAnswerIndex
            notice = onAnswer(question, correct)
            Feedback.answered(correct: correct)
            AccessibilityNotification.Announcement(correct ? "正解です" : "違います。正解は、\(question.correctChoice)").post()
        } label: {
            HStack(alignment: .top, spacing: Theme.spacing.m) {
                Text(numerals[i])
                    .font(.mincho(17, bold: true, relativeTo: .body))
                    .frame(width: 28)
                RubyText(text: question.choices[i], size: 17)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if !mark.isEmpty {
                    Text(mark)
                        .font(.mincho(13, bold: true, relativeTo: .caption))
                        .foregroundStyle(isCorrect ? Theme.washi : Theme.sumi)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(isCorrect ? Theme.sumi : Theme.washiDeep, in: RoundedRectangle(cornerRadius: 3))
                }
            }
            .foregroundStyle(Theme.sumi)
            .padding(Theme.spacing.m)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .contentShape(RoundedRectangle(cornerRadius: Theme.corner))
            .background(answered && isCorrect ? Theme.washiDeep : Color.clear, in: RoundedRectangle(cornerRadius: Theme.corner))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.corner)
                    .stroke(Theme.sumi.opacity(isChosen || (answered && isCorrect) ? 1 : 0.3), lineWidth: isChosen || (answered && isCorrect) ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(numerals[i])、\(question.choices[i])")
        .accessibilityValue(mark)
        .accessibilityIdentifier("choice_\(i)")
    }

    private func explanation(correct: Bool) -> some View {
        LinedPage {
            VStack(alignment: .leading, spacing: Theme.spacing.s) {
                Text(correct ? "正解" : "正解は、\(question.correctChoice)")
                    .font(.mincho(17, bold: true, relativeTo: .headline))
                RubyText(text: question.trivia, size: 16)
                if let notice {
                    Text(notice)
                        .font(.mincho(15, bold: true, relativeTo: .callout))
                        .foregroundStyle(Theme.shuText)
                }
                if let url = URL(string: question.sourceURL) {
                    Link(destination: url) {
                        Label(question.sourceTitle, systemImage: "book.closed")
                            .font(.mincho(13, relativeTo: .footnote))
                    }
                }
            }
            .foregroundStyle(Theme.sumi)
        }
        .accessibilityIdentifier("explanation")
    }

    private func advance() {
        if isLast {
            onFinish()
        } else {
            index += 1
            chosen = nil
            notice = nil
        }
    }
}
