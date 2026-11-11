import SwiftUI

struct RootView: View {
    @State private var store: ProgressStore

    init(store: ProgressStore? = nil) {
        _store = State(initialValue: store ?? ProgressStore())
    }
    @State private var app = AppState()
    var body: some View {
        @Bindable var app = app
        NavigationStack(path: $app.path) {
            Group {
                if !store.progress.welcomed { WelcomeView() }
                else {
                    TabView(selection: $app.tab) {
                        Tab(value: AppTab.home) {
                            HomeView()
                        } label: {
                            Label("Home", systemImage: app.tab == .home ? "house.fill" : "house")
                                .environment(\.symbolVariants, .none)
                        }
                        Tab(value: AppTab.lessons) {
                            LessonListView()
                        } label: {
                            Label("Lessons", systemImage: app.tab == .lessons ? "book.fill" : "book")
                                .environment(\.symbolVariants, .none)
                        }
                        Tab(value: AppTab.challenges) {
                            ChallengeListView()
                        } label: {
                            Label("Challenges", systemImage: app.tab == .challenges ? "medal.fill" : "medal")
                                .environment(\.symbolVariants, .none)
                        }
                        Tab(value: AppTab.progress) {
                            LearningProgressView()
                        } label: {
                            Label("Progress", systemImage: app.tab == .progress ? "chart.bar.fill" : "chart.bar")
                                .environment(\.symbolVariants, .none)
                        }
                    }
                    .tint(AppTheme.coral)
                    .toolbarBackground(AppTheme.surface, for: .tabBar)
                    .toolbarBackground(.visible, for: .tabBar)
                    .toolbarColorScheme(app.appearance.colorScheme, for: .tabBar)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Route.self) { route in
                DestinationView(route: route)
            }
            .toolbarTitleDisplayMode(.inline)
        }
        .background(AppTheme.background)
        .environment(store)
        .environment(app)
        .tint(AppTheme.coral)
        .foregroundStyle(AppTheme.ink)
        .preferredColorScheme(app.appearance.colorScheme)
        .alert("Progress storage", isPresented: Binding(get: { store.storageMessage != nil }, set: { if !$0 { store.storageMessage = nil } })) { Button("Try saving again") { store.storageMessage = nil; store.save() }; Button("OK", role:.cancel) { store.storageMessage = nil } } message: { Text(store.storageMessage ?? "") }
    }
}
struct DestinationView: View {
    let route: Route
    var body: some View {
        Group {
                switch route {
                case .lesson(let id): LessonIntroView(id:id)
                case .reader(let id): LessonReaderView(id:id)
                case .lessonComplete(let id): LessonCompleteView(id:id)
                case .challenge(let id): ChallengeIntroView(id:id)
                case .session(let id,let subject,let difficulty): ChallengeSessionView(id:id,subject:subject,difficulty:difficulty)
                case .result(let id): ChallengeResultView(attemptID:id)
                case .reward(let id,let isNew): BuildingRewardView(attemptID:id,isNew:isNew)
                case .city(let preview): CityView(preview:preview)
                case .cityAddition(let id): CityView(preview: false, newBuildingID: id)
                case .building(let id): BuildingDetailView(id:id)
                case .history(let id): AttemptHistoryView(challengeID:id)
                case .settings: SettingsView()
                }
        }.toolbar(.visible, for: .navigationBar).toolbarTitleDisplayMode(.inline)
    }
}
struct WelcomeView: View {
    @Environment(ProgressStore.self) private var store
    @State private var name = "Alex"

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                CityIllustration(
                    buildings: Set(0..<10),
                    aspectRatio: 405.0 / 430.0,
                    initialVerticalOffset: 50
                )
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                WelcomeNameForm(name: $name) {
                    store.progress.name = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(24))
                    if store.progress.name.isEmpty { store.progress.name = "Alex" }
                    store.progress.welcomed = true
                    store.save()
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 32)
                .frame(maxWidth: 600)
            }
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(AppTheme.background)
        .ignoresSafeArea(.container, edges: [.top, .horizontal])
    }
}

private struct WelcomeNameForm: View {
    @Binding var name: String
    let start: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            PageTitle(text: "Little lessons.\nA city of progress.")
            Text("What should we call you?")
            AnswerField(text: $name, prompt: "Your name")
            QuestButton(title: "Start my city", action: start)
        }
    }
}

#if DEBUG
#Preview("RootView") {
    RootView(store: PreviewData.store())
}

#Preview("DestinationView") {
    PreviewScreen() { DestinationView(route: .challenge(1)) }
}

#Preview("WelcomeView") {
    PreviewScreen() { WelcomeView() }
}
#endif
