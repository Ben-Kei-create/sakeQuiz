import SwiftUI

struct CalendarView: View {
    let library: ContentLibrary
    @Environment(AppModel.self) private var model
    @State private var openLesson: Lesson?
    @State private var showSettings = false

    private var store: ProgressStore { model.store }
    private let columns = [GridItem(.adaptive(minimum: 52), spacing: Theme.spacing.s)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacing.l) {
                header
                todayCard
                VStack(alignment: .leading, spacing: Theme.spacing.s) {
                    Text("仕込み暦")
                        .font(.mincho(17, bold: true, relativeTo: .headline))
                        .accessibilityAddTraits(.isHeader)
                    LazyVGrid(columns: columns, spacing: Theme.spacing.s) {
                        ForEach(library.lessons) { lesson in dayCell(lesson) }
                    }
                }
                Text("お酒は二十歳になってから。")
                    .font(.mincho(13, relativeTo: .footnote))
                    .foregroundStyle(Theme.sumi.opacity(0.8))
            }
            .padding(Theme.spacing.m)
        }
        .background(Theme.washi)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom, spacing: 0) { AdBannerBar() }
        .fullScreenCover(item: $openLesson) { lesson in
            LessonView(library: library, lesson: lesson, readOnly: store.state.completions[lesson.day] != nil)
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("蔵ごよみ")
                    .font(.mincho(34, bold: true, relativeTo: .largeTitle))
                    .foregroundStyle(Theme.sumi)
                    .accessibilityAddTraits(.isHeader)
                Text("杜氏の仕込み帳")
                    .font(.mincho(15, relativeTo: .subheadline))
                    .foregroundStyle(Theme.sumi.opacity(0.8))
            }
            Spacer()
            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.title3)
                    .foregroundStyle(Theme.sumi)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .accessibilityLabel("設定")
            .accessibilityIdentifier("settings_button")
        }
    }

    private var todayCard: some View {
        LinedPage {
            VStack(alignment: .leading, spacing: Theme.spacing.m) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(min(store.completedCount + 1, library.lessons.count))日目")
                        .font(.numeral(28))
                    Text("／\(library.lessons.count)日")
                        .font(.mincho(15, relativeTo: .subheadline))
                    Spacer()
                    Text("続けて \(store.streak(on: model.now)) 日")
                        .font(.mincho(15, relativeTo: .subheadline))
                }
                .foregroundStyle(Theme.sumi)
                .accessibilityElement(children: .combine)

                if let day = store.nextLessonDay, let lesson = library.lesson(day: day) {
                    if model.isTodayOpen {
                        Text(lesson.title)
                            .font(.mincho(22, bold: true, relativeTo: .title2))
                            .foregroundStyle(Theme.sumi)
                        Button { openLesson = lesson } label: { Text("今日の仕込みへ") }
                            .buttonStyle(PrimaryButtonStyle())
                            .accessibilityIdentifier("start_lesson_button")
                    } else {
                        closedNotice("本日の仕込み、終わり。\nつぎは、明日。")
                    }
                } else {
                    closedNotice("仕込み、すべて終わり。\nお疲れさまでした。")
                }
            }
            .foregroundStyle(Theme.sumi)
        }
    }

    private func closedNotice(_ text: String) -> some View {
        HStack(spacing: Theme.spacing.m) {
            Seal(text: "済", size: 52)
            Text(text)
                .font(.mincho(17, bold: true, relativeTo: .headline))
                .foregroundStyle(Theme.sumi)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("closed_notice")
    }

    @ViewBuilder
    private func dayCell(_ lesson: Lesson) -> some View {
        let done = store.state.completions[lesson.day] != nil
        let isNext = lesson.day == store.nextLessonDay
        let label = done ? "\(lesson.day)日目 \(lesson.title) 仕込み済み"
            : isNext ? "\(lesson.day)日目 \(lesson.title) 次の仕込み" : "\(lesson.day)日目 まだ"
        let cell = ZStack {
            RoundedRectangle(cornerRadius: Theme.corner)
                .fill(done ? Theme.shu : Color.clear)
            RoundedRectangle(cornerRadius: Theme.corner)
                .stroke(isNext ? Theme.shuText : Theme.sumi.opacity(done ? 0 : 0.3), lineWidth: isNext ? 2 : 1)
            VStack(spacing: 0) {
                Text("\(lesson.day)")
                    .font(.numeral(17, relativeTo: .body))
                if done { Text("済").font(.mincho(11, bold: true, relativeTo: .caption2)) }
            }
            .foregroundStyle(done ? Theme.washi : Theme.sumi.opacity(isNext ? 1 : 0.55))
        }
        .frame(minHeight: 52)
        if done {
            Button { openLesson = lesson } label: { cell }
                .buttonStyle(.plain)
                .accessibilityLabel(label)
                .accessibilityHint("読み返します")
        } else {
            cell.accessibilityElement(children: .ignore).accessibilityLabel(label)
        }
    }
}
