import Combine
import SwiftUI

struct QuizView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    @Environment(GameStore.self) private var store
    @AppStorage(QuizTimer.disabledKey) private var timerDisabled = false

    let mode: QuizMode

    @State var session: QuizSession
    @State private var isNewHighScore = false
    @State private var selectedIndex: Int?
    @State private var lastAnswer: AnswerRecord?
    @State private var timeRemaining: Int

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(session: QuizSession, mode: QuizMode = .normal) {
        self.mode = mode
        _session = State(initialValue: session)
        _timeRemaining = State(initialValue: session.currentQuestion?.difficulty.timeLimit ?? 20)
    }

    var body: some View {
        ZStack {
            NihonshuBackdrop()

            if session.isComplete {
                ResultView(
                    session: session,
                    restart: restart,
                    close: { dismiss() },
                    canRestart: mode == .normal,
                    isNewHighScore: isNewHighScore
                )
            } else if let question = session.currentQuestion {
                questionBody(question)
            } else {
                UnavailableView(message: "表示できる問題がありません。")
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !session.isComplete, session.currentQuestion != nil {
                VStack(spacing: 0) {
                    if lastAnswer != nil {
                        // 解説が長くても「次へ」が広告やスクロールに隠れないよう、画面下に固定する。
                        Button(action: continueQuiz) {
                            Label("次へ", systemImage: "arrow.right")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(NihonshuPrimaryButtonStyle())
                        .padding(.horizontal, 20).padding(.vertical, 10)
                        .background(NihonshuTheme.kinari)
                        .accessibilityIdentifier("next_question_button")
                    }
                    AdBannerBar()
                }
            }
        }
    .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if !session.isComplete, session.currentQuestion != nil {
                    Text(session.progressText)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(NihonshuTheme.sumi)
                }
            }
            ToolbarItem(placement: .principal) {
                if !session.isComplete, session.currentQuestion != nil {
                    HStack(spacing: 8) {
                        ProgressView(value: Double(session.currentIndex + 1), total: Double(session.questions.count))
                            .tint(NihonshuTheme.indigo)
                            .frame(width: 80)
                            .accessibilityLabel("進み具合")
                            .accessibilityValue(session.progressText)
                        if !timerDisabled {
                            Label("あと\(timeRemaining)秒", systemImage: timeRemaining <= 5 ? "exclamationmark.triangle.fill" : "timer")
                                .fixedSize()
                                .font(.caption.monospacedDigit().weight(.bold))
                                .foregroundStyle(timeRemaining <= 5 ? NihonshuTheme.shu : NihonshuTheme.success)
                                .accessibilityLabel("残り\(timeRemaining)秒")
                        }
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Text("正解 \(session.score)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(NihonshuTheme.sumi)
            }
        }
        .onReceive(timer) { _ in
            guard scenePhase == .active, !timerDisabled, lastAnswer == nil, !session.isComplete else {
                return
            }

            if timeRemaining > 0 { timeRemaining -= 1 }
            if timeRemaining == 0 { submitAnswer(nil) }
        }
    }

    private func questionBody(_ question: QuizQuestion) -> some View {
        ScrollViewReader { proxy in
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Color.clear.frame(height: 0).id("questionTop")
                NihonshuPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 8) {
                            NihonshuChip(title: question.difficulty.localizedName, color: difficultyColor(question.difficulty))
                            NihonshuChip(title: question.category.localizedName, color: NihonshuTheme.seiji)
                        }

                        Text(question.question)
                            .font(.title2.weight(.black))
                            .foregroundStyle(NihonshuTheme.sumi)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                    }
                }

                VStack(spacing: 12) {
                    ForEach(question.choices.indices, id: \.self) { index in
                        ChoiceButton(
                            text: question.choices[index],
                            position: index + 1,
                            state: choiceState(for: index, question: question),
                            action: { submitAnswer(index) }
                        )
                        .accessibilityIdentifier("choice_\(index)")
                    }
                }

                if let lastAnswer {
                    AnswerExplanationView(answer: lastAnswer)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .scrollIndicators(.hidden)
        .onChange(of: session.currentIndex) { _, _ in
            proxy.scrollTo("questionTop", anchor: .top)
        }
        }
    }

    private var statusBar: some View {
        NihonshuPanel(cornerRadius: 22) {
            VStack(spacing: 12) {
                HStack {
                    Text(session.progressText)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(NihonshuTheme.sumi)

                    Spacer()

                    Text("あと\(timeRemaining)秒").fixedSize()
                        .font(.headline.monospacedDigit().weight(.bold))
                        .foregroundStyle(timeRemaining <= 5 ? NihonshuTheme.indigo : NihonshuTheme.success)
                }

                ProgressView(value: Double(session.currentIndex + 1), total: Double(session.questions.count))
                    .tint(NihonshuTheme.indigo)
            }
        }
    }

    private func choiceState(for index: Int, question: QuizQuestion) -> ChoiceButton.State {
        guard let lastAnswer else {
            return selectedIndex == index ? .selected : .idle
        }

        if index == question.correctAnswerIndex {
            return .correct
        }

        if lastAnswer.selectedIndex == index {
            return .incorrect
        }

        return .idle
    }

    private func submitAnswer(_ index: Int?) {
        guard lastAnswer == nil else {
            return
        }

        selectedIndex = index
        lastAnswer = session.answerCurrentQuestion(selectedIndex: index)

        if let lastAnswer {
            store.recordAnswer(lastAnswer)

            if mode == .daily {
                store.recordDailyCompleted()
            }
        }

        if let lastAnswer {
            let message = lastAnswer.isCorrect ? "正解です" : "不正解です。正解は\(lastAnswer.question.correctChoice)"
            AccessibilityNotification.Announcement(message).post()
        }

        if lastAnswer?.isCorrect == true {
            SoundPlayer.playCorrect()
        } else {
            SoundPlayer.playIncorrect()
        }
    }

    private func continueQuiz() {
        if session.isLastQuestion {
            session.moveToNextQuestion()

            if mode == .normal {
                isNewHighScore = store.recordGameFinished(score: session.score)
            }

            SoundPlayer.playFinish()
            return
        }

        session.moveToNextQuestion()
        selectedIndex = nil
        lastAnswer = nil
        timeRemaining = session.currentQuestion?.difficulty.timeLimit ?? 20
    }

    private func restart() {
        let sourceQuestions = session.questions
        session = QuizSession(questions: sourceQuestions, questionLimit: sourceQuestions.count, shuffle: true)
        isNewHighScore = false
        selectedIndex = nil
        lastAnswer = nil
        timeRemaining = session.currentQuestion?.difficulty.timeLimit ?? 20
    }

    private func difficultyColor(_ difficulty: Difficulty) -> Color {
        switch difficulty {
        case .easy:
            return NihonshuTheme.seiji
        case .medium:
            return NihonshuTheme.kincha
        case .hard:
            return NihonshuTheme.shu
        }
    }
}

private struct ChoiceButton: View {
    enum State {
        case idle
        case selected
        case correct
        case incorrect
    }

    let text: String
    let position: Int
    let state: State
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .frame(width: 24)

                Text(text)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .accessibilityLabel("選択肢\(position)、\(text)")
        .accessibilityValue(stateDescription)
    }

    private var stateDescription: String {
        switch state {
        case .idle: return ""
        case .selected: return "選択中"
        case .correct: return "正解"
        case .incorrect: return "あなたの答え、不正解"
        }
    }

    private var iconName: String {
        switch state {
        case .idle:
            "circle"
        case .selected:
            "largecircle.fill.circle"
        case .correct:
            "checkmark.circle.fill"
        case .incorrect:
            "xmark.circle.fill"
        }
    }

    private var backgroundColor: Color {
        switch state {
        case .idle:
            Color.white.opacity(0.62)
        case .selected:
            NihonshuTheme.kincha.opacity(0.26)
        case .correct:
            NihonshuTheme.success.opacity(0.22)
        case .incorrect:
            NihonshuTheme.shu.opacity(0.14)
        }
    }

    private var borderColor: Color {
        switch state {
        case .idle:
            Color.white.opacity(0.58)
        case .selected:
            NihonshuTheme.indigo
        case .correct:
            NihonshuTheme.success
        case .incorrect:
            NihonshuTheme.shu
        }
    }
}

private struct AnswerExplanationView: View {
    let answer: AnswerRecord

    var body: some View {
        NihonshuPanel {
            VStack(alignment: .leading, spacing: 12) {
                Label(answer.isCorrect ? "正解です" : "答えを確認", systemImage: answer.isCorrect ? "checkmark.seal.fill" : "lightbulb.fill")
                    .font(.headline)
                    .foregroundStyle(answer.isCorrect ? NihonshuTheme.success : NihonshuTheme.shu)

                Text("正解: \(answer.question.correctChoice)")
                    .font(.subheadline.bold())
                    .foregroundStyle(NihonshuTheme.sumi)

                Text(answer.question.trivia)
                    .font(.body)
                    .foregroundStyle(NihonshuTheme.sumi.opacity(0.82))

                if let title = answer.question.sourceTitle,
                   let address = answer.question.sourceURL, let url = URL(string: address) {
                    Link(destination: url) {
                        Label(title, systemImage: "book.closed").font(.caption)
                    }
                }

            }
        }
    }
}
