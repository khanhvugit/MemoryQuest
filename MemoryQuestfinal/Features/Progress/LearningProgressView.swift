import SwiftUI

struct LearningSummary {
    let attempts: [ChallengeAttempt]
    let results: [QuestionResult]
    let missed: [QuestionResult]
    let recovered: [QuestionResult]
    let delayed: [QuestionResult]
    let reviews: [ReviewRecord]
    init(progress: LearningProgress) {
        attempts=progress.attempts.filter { $0.subject == progress.subject }
        results=attempts.filter { !$0.selfRated }.flatMap(\.results)
        var latest: [String: QuestionResult] = [:]
        var previouslyMissed: Set<String> = []
        var recoveredIDs: Set<String> = []
        for result in results {
            if result.correct && previouslyMissed.contains(result.conceptID) { recoveredIDs.insert(result.conceptID) }
            if !result.correct { previouslyMissed.insert(result.conceptID); recoveredIDs.remove(result.conceptID) }
            latest[result.conceptID]=result
        }
        missed=latest.values.filter { !$0.correct }.sorted { $0.term < $1.term }
        recovered=latest.values.filter { $0.correct && recoveredIDs.contains($0.conceptID) }.sorted { $0.term < $1.term }
        delayed=results.filter { $0.delayed && !$0.sample }
        reviews=progress.reviews.filter { $0.subject == progress.subject }.sorted { $0.due < $1.due }
    }
    func percentage(_ values: [QuestionResult]) -> String { values.isEmpty ? "—" : "\(Int((Double(values.filter(\.correct).count)/Double(values.count)*100).rounded()))%" }
}
struct LearningProgressView: View {
    @Environment(ProgressStore.self) private var store
    @Environment(AppState.self) private var app
    var body: some View {
        let summary=LearningSummary(progress:store.progress)
        QuestPage {
            HStack(spacing: 8) {
                Text("Progress").font(.largeTitle.bold())
                Spacer(minLength: 0)
                LessonSubjectMenu()
            }.padding(.top, 8)
            QuestCard {
                HStack {
                    Text("Your learning journey").font(.title3)
                    Spacer()
                    Text("\(store.progress.completion)%").font(.title3.bold())
                }
                ProgressView(value:Double(store.progress.completedLessons.count+store.progress.buildings.count),total:15)
                Text("Completion of 5 lessons and 10 challenges.").font(.caption).foregroundStyle(AppTheme.muted)
            }
            LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:12) {
                ProgressMetric(value:"\(store.progress.completedLessons.count)/5",title:"Lessons explored")
                ProgressMetric(value:"\(store.progress.buildings.count)/10",title:"Buildings constructed")
                ProgressMetric(value:summary.percentage(summary.results),title:"Accuracy")
                ProgressMetric(value:summary.percentage(summary.delayed),title:"Delayed review recall")
            }
            if !summary.attempts.isEmpty {
                DisclosureGroup("Learning details") {
                    VStack(alignment: .leading, spacing: 20) {
            Text("Completion is shared across subjects. Performance and reviews below are for \(store.progress.subject.title). Self-rated flashcards are excluded from scored accuracy. Checklist coverage uses predefined rules. Delayed recall requires genuine history at least a day earlier; sample history and immediate replays are excluded.").font(.caption).foregroundStyle(AppTheme.muted)
            AttemptComparisonView(attempts:summary.attempts)
            Text("Ideas you can now recall").font(.title3.bold())
            if summary.recovered.isEmpty { Text("Previously missed ideas appear here when you retrieve them correctly.").font(.subheadline).foregroundStyle(AppTheme.muted) }
            else { QuestCard { ForEach(summary.recovered) { Label($0.term,systemImage:"checkmark.circle").foregroundStyle(.green) }; Text("Missed earlier, correct in your latest recorded check.").font(.caption) } }
            Text("Practise next").font(.title3.bold())
            if summary.missed.isEmpty { Text("No outstanding missed ideas yet. Return to completed questions after a delay.").font(.subheadline).foregroundStyle(AppTheme.muted) }
            else { QuestCard { ForEach(summary.missed.prefix(8)) { result in Text(result.term).font(.headline); Text(result.expected).font(.subheadline).foregroundStyle(AppTheme.muted) } } }
            Text("Scheduled reviews").font(.title3.bold())
            if summary.reviews.isEmpty { Text("No scheduled reviews yet. Memory Comeback and Rescue Forgotten Words schedule your next retrieval.").font(.subheadline).foregroundStyle(AppTheme.muted) }
            else {
                QuestCard {
                    if !summary.reviews.contains(where:{ $0.due <= Date() }) { Text("No reviews due today.").font(.headline) }
                    ForEach(summary.reviews) { review in MetricRow(title:review.term,value:"\(review.due <= Date() ? "Due · " : "")\(review.due.formatted(date:.abbreviated,time:.omitted))") }
                    QuestButton(title:"Review concepts",secondary:true) { app.path.append(.challenge(6)) }
                }
            }
            Text("Learning milestones").font(.title3.bold())
            QuestCard {
                Label(store.progress.buildings.isEmpty ? "Your first building is ahead" : "First building constructed",systemImage:"flag")
                if store.progress.completedLessons.count == 5 { Label("All five strategies explored",systemImage:"rosette") }
                if store.progress.buildings.count == 10 { Label("Your complete learning city",systemImage:"trophy") }
            }
            Text("Previous challenge results").font(.title3.bold())
            if summary.attempts.isEmpty { Text("Your results appear after your first challenge.").font(.subheadline).foregroundStyle(AppTheme.muted) }
            ForEach(ContentRepository.challenges.filter { c in summary.attempts.contains { $0.challengeID == c.id } }) { c in
                QuestButton(title:c.title,secondary:true) { app.path.append(.history(c.id)) }
            }
            QuestButton(title:"Settings",secondary:true) { app.path.append(.settings) }
            Text("These activities show learning performance, not a measure of general memory ability.").font(.caption).foregroundStyle(AppTheme.muted)
                    }
                    .padding(.top, 16)
                }
            }
        }
    }
}
struct ProgressMetric: View {
    let value, title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(value).font(.largeTitle.bold())
            Text(title).font(.subheadline).foregroundStyle(AppTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 90, alignment: .leading)
        .padding(20)
        .background(Color("CardBackground"), in: RoundedRectangle(cornerRadius: 18))
    }
}
struct AttemptComparisonView: View {
    let attempts: [ChallengeAttempt]
    var body: some View {
        let repeated=ContentRepository.challenges.filter { c in attempts.filter { $0.challengeID == c.id }.count > 1 }
        VStack(alignment:.leading,spacing:16) {
            Text("Improvement over attempts").font(.title3.bold())
            if repeated.isEmpty { QuestCard { Text("Replay a challenge to compare your first and latest results. No improvement is assumed before you practise.").font(.subheadline).foregroundStyle(AppTheme.muted) } }
            ForEach(repeated) { c in
                let history=attempts.filter { $0.challengeID == c.id }
                if let first=history.first, let last=history.last {
                    QuestCard {
                        Text(c.title + (c.id == 1 ? " · self-rated" : c.id == 8 ? " · checklist coverage" : "")).font(.headline)
                        MetricRow(title:"First attempt",value:"\(first.score)%")
                        ProgressView(value:Double(first.score),total:100)
                        MetricRow(title:"Latest attempt",value:"\(last.score)%")
                        ProgressView(value:Double(last.score),total:100)
                        Text("\(last.score-first.score >= 0 ? "+" : "")\(last.score-first.score) percentage points · \(last.date.formatted(date:.abbreviated,time:.omitted))").font(.caption).foregroundStyle(AppTheme.muted)
                    }
                }
            }
        }
    }
}

#if DEBUG
#Preview("LearningProgressView") {
    PreviewScreen() { LearningProgressView() }
}

#Preview("ProgressMetric") {
    PreviewScreen() { ProgressMetric(value: "1/5", title: "Lessons explored") }
}

#Preview("AttemptComparisonView") {
    PreviewScreen() { AttemptComparisonView(attempts: [PreviewData.attempt, PreviewData.attempt]) }
}
#endif
