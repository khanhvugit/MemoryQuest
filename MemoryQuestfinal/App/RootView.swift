import SwiftUI

struct RootView: View {
    @State private var store = ProgressStore()
    @State private var app = AppState()
    var body: some View {
        @Bindable var app = app
        VStack(spacing: 0) {
        NavigationStack(path: $app.path) {
            Group {
                if !store.progress.welcomed { WelcomeView() }
                else {
                    switch app.tab {
                    case .home: HomeView()
                    case .lessons: LessonListView()
                    case .challenges: ChallengeListView()
                    case .progress: LearningProgressView()
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Route.self) { route in
                DestinationView(route: route)
            }
            .toolbarTitleDisplayMode(.inline)
        }
        if store.progress.welcomed { BottomNavigation(selected: app.selectedTab) { app.navigate($0) } }
        }
        .background(AppTheme.background)
        .environment(store).environment(app).tint(AppTheme.coral).foregroundStyle(AppTheme.ink).preferredColorScheme(.light)
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
                case .building(let id, let preview): BuildingDetailView(id:id, preview:preview)
                case .history(let id): AttemptHistoryView(challengeID:id)
                case .settings: SettingsView()
                }
        }.toolbar(.visible, for: .navigationBar).toolbarTitleDisplayMode(.inline)
    }
}
struct BottomNavigation: View {
    let selected: AppTab
    let select: (AppTab) -> Void
    var body: some View {
        HStack(spacing:0) {
            ForEach(AppTab.allCases) { tab in
                Button { select(tab) } label: {
                    VStack(spacing:5) { Image(systemName:tab.symbol).font(.system(size:21)); Text(tab.rawValue).font(.caption) }
                        .frame(maxWidth:.infinity).padding(.vertical,10).background(selected == tab ? AppTheme.line : .clear,in:Capsule())
                }.buttonStyle(.plain).accessibilityAddTraits(selected == tab ? .isSelected : [])
            }
        }.padding(5).background(.white,in:Capsule()).overlay(Capsule().stroke(Color(hex:"efedf0"))).padding(.horizontal,14).padding(.vertical,8).background(AppTheme.background)
    }
}
struct WelcomeView: View {
    @Environment(ProgressStore.self) private var store
    @State private var name = "Alex"
    var body: some View {
        QuestPage {
            Label("MemoryQuest",systemImage:"brain").font(.headline).foregroundStyle(.purple)
            CityIllustration(buildings:Set(0..<10)).allowsHitTesting(false)
            PageTitle(text:"Little lessons.\nA city of progress.")
            Text("Discover memory strategies, practise with computer science or biology, and build something you can be proud of.").foregroundStyle(AppTheme.muted)
            Text("5 memory strategies · 10 buildings to unlock").font(.caption)
            Text("What should we call you?")
            AnswerField(text:$name,prompt:"Your name")
            QuestButton(title:"Start my city") { store.progress.name = String(name.trimmingCharacters(in:.whitespacesAndNewlines).prefix(24)); if store.progress.name.isEmpty { store.progress.name = "Alex" }; store.progress.welcomed = true; store.save() }
            Text("Your city grows one completed challenge at a time.").font(.caption).foregroundStyle(AppTheme.muted)
        }
    }
}
