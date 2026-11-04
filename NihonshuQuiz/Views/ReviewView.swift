import SwiftUI

struct ReviewView: View {
    let library: ContentLibrary
    @Environment(AppModel.self) private var model
    @State private var running = false

    private var due: [QuizQuestion] {
        model.store.dueReviewIDs(on: model.now).compactMap { library.questions[$0] }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacing.l) {
            Text("復習")
                .font(.mincho(34, bold: true, relativeTo: .largeTitle))
                .accessibilityAddTraits(.isHeader)
            if due.isEmpty {
                VStack(alignment: .leading, spacing: Theme.spacing.m) {
                    if Illustration.exists("illust_sugidama") {
                        Illustration(name: "illust_sugidama", height: 140)
                    } else {
                        Seal(text: "無", size: 52)
                    }
                    Text(model.store.state.reviews.isEmpty ? "間違えた問いは、まだない。" : "本日の復習は、なし。")
                        .font(.mincho(17, bold: true, relativeTo: .headline))
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("review_empty")
                Text("間違えた問いは、翌日、3日後、7日後に、もう一度出る。")
                    .font(.mincho(15, relativeTo: .subheadline))
                    .foregroundStyle(Theme.sumi.opacity(0.85))
            } else {
                Text("\(due.count)問、復習する。")
                    .font(.mincho(19, bold: true, relativeTo: .title3))
                Button { running = true } label: { Text("復習をはじめる") }
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier("start_review_button")
            }
            Spacer()
        }
        .foregroundStyle(Theme.sumi)
        .padding(Theme.spacing.m)
        .background(Theme.washi)
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $running) {
            ReviewSession(library: library, questions: due)
        }
    }
}

private struct ReviewSession: View {
    let library: ContentLibrary
    let questions: [QuizQuestion]
    @Environment(\.dismiss) private var dismiss
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Label("閉じる", systemImage: "xmark")
                        .font(.mincho(15, relativeTo: .body))
                        .foregroundStyle(Theme.sumi)
                        .frame(minHeight: 44)
                }
                Spacer()
            }
            .padding(.horizontal, Theme.spacing.m)
            QuestionFlowView(questions: questions, finishTitle: "復習を終える") { question, correct in
                model.store.recordReviewAnswer(questionID: question.id, isCorrect: correct, on: model.now)
                if correct, let seal = library.seal(forQuestion: question.id), model.store.awardSeal(seal.id, on: model.now) {
                    Feedback.stamped()
                    return "蔵印帳に、「\(seal.name)」の印を押した。"
                }
                return nil
            } onFinish: { dismiss() }
        }
        .background(Theme.washi)
    }
}
