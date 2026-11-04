import SwiftUI

struct RootView: View {
    @State private var model = AppModel()
    @State private var showLaunch = LaunchFlipbook.shouldShow()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(ReminderCenter.self) private var reminder

    var body: some View {
        Group {
            if let message = model.loadError {
                UnavailableView(message: message)
            } else if let library = model.library {
                MainTabs(library: library)
                    .environment(model)
                    .environment(model.store)
            }
        }
        .overlay {
            if showLaunch {
                LaunchFlipbook { withAnimation(.easeOut(duration: 0.2)) { showLaunch = false } }
                    .transition(.opacity)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                model.refreshClock()
                Task { await reminder.reschedule(store: model.store, now: model.now) }
            }
        }
        .onChange(of: model.store.completedCount) { _, _ in
            Task { await reminder.reschedule(store: model.store, now: model.now) }
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            model.refreshClock()
        }
    }
}

private struct MainTabs: View {
    let library: ContentLibrary

    var body: some View {
        TabView {
            NavigationStack { CalendarView(library: library) }
                .tabItem { Label("仕込み暦", systemImage: "calendar") }
            NavigationStack { ReviewView(library: library) }
                .tabItem { Label("復習", systemImage: "arrow.triangle.2.circlepath") }
            NavigationStack { SealBookView(library: library) }
                .tabItem { Label("蔵印帳", systemImage: "book.closed") }
        }
        .tint(Theme.shuText)
    }
}
