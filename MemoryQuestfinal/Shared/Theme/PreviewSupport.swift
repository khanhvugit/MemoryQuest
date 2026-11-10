#if DEBUG
import SwiftUI

@MainActor
enum PreviewData {
    static let attempt = ChallengeAttempt(
        id: UUID(), challengeID: 0, subject: .computerScience, difficulty: .easy,
        date: Date(), duration: 60,
        results: [
            QuestionResult(conceptID: "stack", term: "Stack", answer: "Stack",
                           expected: "Stack", explanation: "Last in, first out.", correct: true),
            QuestionResult(conceptID: "queue", term: "Queue", answer: "Array",
                           expected: "Queue", explanation: "First in, first out.", correct: false)
        ], selfRated: false
    )

    static func store(completed: Bool = true, results: Bool = false) -> ProgressStore {
        // Each preview writes only to its own temporary directory.
        let store = ProgressStore(url: URL.temporaryDirectory
            .appending(path: "MemoryQuestPreviews/\(UUID().uuidString)/progress.json"))
        store.progress.welcomed = true
        store.progress.completedLessons = completed ? [0] : []
        if results { store.progress.attempts = [attempt] }
        return store
    }

    static func session(_ id: Int) -> ChallengeSessionViewModel {
        ChallengeSessionViewModel(id: id, subject: .computerScience, difficulty: .easy, history: [])
    }
}

struct PreviewScreen<Content: View>: View {
    @State private var store: ProgressStore
    @State private var app = AppState()
    private let content: Content

    init(completed: Bool = true, results: Bool = false, @ViewBuilder content: () -> Content) {
        _store = State(initialValue: PreviewData.store(completed: completed, results: results))
        self.content = content()
    }

    var body: some View {
        @Bindable var app = app
        NavigationStack(path: $app.path) {
            content
                .navigationDestination(for: Route.self) { DestinationView(route: $0) }
                .toolbarTitleDisplayMode(.inline)
        }
        .environment(store)
        .environment(app)
        .tint(AppTheme.coral)
        .foregroundStyle(AppTheme.ink)
        .preferredColorScheme(.light)
    }
}

#Preview("Preview container") {
    PreviewScreen { HomeView() }
}
#endif
