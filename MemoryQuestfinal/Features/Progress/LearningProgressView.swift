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
            LazyVGrid(columns: [GridItem(.flexible(), alignment: .top), GridItem(.flexible(), alignment: .top)], spacing: 12) {
                ProgressMetric(value:"\(store.progress.completedLessons.count)/5",title:"Lessons explored")
                ProgressMetric(value:"\(store.progress.buildings.count)/10",title:"Buildings constructed")
                ProgressMetric(value:summary.percentage(summary.results),title:"Accuracy")
                ProgressMetric(value:summary.percentage(summary.delayed),title:"Delayed review recall")
            }
            if !summary.attempts.isEmpty {
                DisclosureGroup("Learning details") {
                    VStack(alignment: .leading, spacing: 20) {
                        if !summary.missed.isEmpty {
                            Text("Practise next").font(.headline)
                            QuestCard {
                                ForEach(summary.missed.prefix(5)) { result in
                                    Text(result.term).font(.subheadline)
                                }
                            }
                        }
                        if !summary.reviews.isEmpty {
                            Text("Scheduled reviews").font(.headline)
                            QuestCard {
                                ForEach(Array(summary.reviews.prefix(3))) { review in
                                    MetricRow(
                                        title: review.term,
                                        value: review.due <= Date() ? "Due now" : review.due.formatted(date: .abbreviated, time: .omitted)
                                    )
                                }
                                QuestButton(title: "Review concepts", secondary: true) {
                                    app.path.append(.challenge(6))
                                }
                            }
                        }
                        Text("Previous results").font(.headline)
                        ForEach(ContentRepository.challenges.filter { challenge in
                            summary.attempts.contains { $0.challengeID == challenge.id }
                        }) { challenge in
                            QuestButton(title: challenge.title, secondary: true) {
                                app.path.append(.history(challenge.id))
                            }
                        }
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
            Text(value).font(.largeTitle.bold()).monospacedDigit()
            Text(title).font(.subheadline).foregroundStyle(AppTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 90, alignment: .topLeading)
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
