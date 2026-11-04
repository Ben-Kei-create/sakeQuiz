import SwiftUI

/// 今日の仕込み。読む → 答える → 判を押す。
struct LessonView: View {
    let library: ContentLibrary
    let lesson: Lesson
    let readOnly: Bool

    @Environment(\.dismiss) private var dismiss
    @Environment(AppModel.self) private var model
    @Environment(ReminderCenter.self) private var reminder
    @State private var speaker = Speaker()
    @State private var phase: Phase = .reading
    @State private var stamped = false

    private enum Phase { case reading, questions, done }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            switch phase {
            case .reading: reading
            case .questions:
                QuestionFlowView(questions: library.questions(for: lesson), finishTitle: "仕込みを終える",
                                 onAnswer: record, onFinish: finish)
            case .done: done
            }
        }
        .background(Theme.washi)
        .onDisappear { speaker.stop() }
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Label("閉じる", systemImage: "xmark")
                    .labelStyle(.titleAndIcon)
                    .font(.mincho(15, relativeTo: .body))
                    .foregroundStyle(Theme.sumi)
                    .frame(minHeight: 44)
            }
            .accessibilityIdentifier("close_button")
            Spacer()
            Text("\(lesson.day)日目")
                .font(.numeral(17, relativeTo: .headline))
                .foregroundStyle(Theme.sumi)
        }
        .padding(.horizontal, Theme.spacing.m)
    }

    private var reading: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacing.l) {
                RubyText(text: lesson.title, size: 30, bold: true, style: .largeTitle)
                    .accessibilityAddTraits(.isHeader)
                RubyText(text: lesson.body, size: 19)
                Button { speaker.toggle("\(lesson.title)。\(lesson.body)") } label: {
                    Label(speaker.isSpeaking ? "読み上げを止める" : "読み上げる", systemImage: speaker.isSpeaking ? "stop.circle" : "speaker.wave.2")
                        .font(.mincho(15, relativeTo: .body))
                        .frame(minHeight: 44)
                }
                .accessibilityIdentifier("speak_button")
                if let url = URL(string: lesson.sourceURL) {
                    Link(destination: url) {
                        Label(lesson.sourceTitle, systemImage: "book.closed")
                            .font(.mincho(13, relativeTo: .footnote))
                    }
                }
            }
            .foregroundStyle(Theme.sumi)
            .padding(Theme.spacing.m)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button {
                speaker.stop()
                if readOnly { dismiss() } else { phase = .questions }
            } label: { Text(readOnly ? "閉じる" : "読み終えた") }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, Theme.spacing.m)
                .padding(.vertical, Theme.spacing.s)
                .background(Theme.washi)
                .accessibilityIdentifier("finish_reading_button")
        }
    }

    private var done: some View {
        VStack(spacing: Theme.spacing.l) {
            Spacer()
            Illustration(name: "illust_okeoke")
            Seal(text: stamped ? "仕込済" : "仕込", size: Illustration.exists("illust_okeoke") ? 88 : 120)
            Text("本日の仕込み、終わり。")
                .font(.mincho(24, bold: true, relativeTo: .title))
                .foregroundStyle(Theme.sumi)
                .accessibilityAddTraits(.isHeader)
            Text("続けて \(model.store.streak(on: model.now)) 日")
                .font(.mincho(17, relativeTo: .headline))
                .foregroundStyle(Theme.sumi)
            if reminder.shouldOffer(completedDays: model.store.completedCount) { reminderOffer }
            Spacer()
            Button { dismiss() } label: { Text("帳面へ戻る") }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, Theme.spacing.m)
                .accessibilityIdentifier("back_to_book_button")
            BannerSlot()
        }
    }

    /// 3日続けた人に、1回だけ。断っても、二度と頼まない。
    private var reminderOffer: some View {
        LinedPage {
            VStack(alignment: .leading, spacing: Theme.spacing.s) {
                Text("毎日の仕込みを、お知らせしましょうか。")
                    .font(.mincho(17, bold: true, relativeTo: .headline))
                Text("決めた時刻に、端末の中から、1日1回だけ知らせます。設定でいつでも止められます。")
                    .font(.mincho(14, relativeTo: .footnote))
                HStack(spacing: Theme.spacing.m) {
                    Button("お知らせする") { Task { await reminder.enable(); await reminder.reschedule(store: model.store, now: model.now) } }
                        .accessibilityIdentifier("reminder_yes")
                    Button("いまは、いい") { reminder.declineOffer() }
                        .accessibilityIdentifier("reminder_no")
                }
                .font(.mincho(16, bold: true, relativeTo: .body))
                .foregroundStyle(Theme.shuText)
            }
            .foregroundStyle(Theme.sumi)
        }
        .padding(.horizontal, Theme.spacing.m)
    }

    private func record(_ question: QuizQuestion, _ correct: Bool) -> String? {
        model.store.recordLessonAnswer(questionID: question.id, isCorrect: correct, on: model.now)
        if correct, let seal = library.seal(forQuestion: question.id),
           model.store.awardSeal(seal.id, on: model.now) {
            Feedback.stamped()
            return "蔵印帳に、「\(seal.name)」の印を押した。"
        }
        return nil
    }

    private func finish() {
        stamped = model.store.completeLesson(day: lesson.day, on: model.now)
        phase = .done
    }
}
