import SwiftUI

struct AttemptHistoryView: View {
    let challengeID: Int
    @Environment(ProgressStore.self) private var store
    @Environment(AppState.self) private var app
    var body: some View {
        let attempts=store.attempts(challengeID,subject:store.progress.subject).reversed()
        QuestPage {
            PageTitle(text:ContentRepository.challenges[challengeID].title)
            SubjectPicker()
            Text("Your attempt history · \(attempts.count) attempts").font(.subheadline).foregroundStyle(AppTheme.muted)
            if attempts.isEmpty { QuestCard { Text("No attempts yet.") } }
            ForEach(Array(attempts)) { attempt in
                QuestCard {
                    HStack { Text("\(attempt.score)% \(attempt.selfRated ? "self-rated" : attempt.challengeID == 8 ? "checklist coverage" : "")").font(.headline); Spacer(); Text(attempt.difficulty.rawValue).font(.caption) }
                    Text("\(attempt.date.formatted(date:.abbreviated,time:.shortened)) · \(attempt.duration)s · \(attempt.results.filter(\.correct).count)/\(attempt.results.count) correct checks").font(.caption).foregroundStyle(AppTheme.muted)
                    DisclosureGroup("Review answers and missed ideas") { AttemptAnswersView(results:attempt.results) }
                }
            }
            QuestButton(title:attempts.isEmpty ? "View challenge" : "Replay challenge") { app.path.append(.challenge(challengeID)) }
        }.navigationTitle("Previous results")
    }
}

#if DEBUG
#Preview("AttemptHistoryView") {
    PreviewScreen(results: true) { AttemptHistoryView(challengeID: 0) }
}
#endif
