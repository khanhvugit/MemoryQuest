import SwiftUI

struct HomeView: View {
    @Environment(ProgressStore.self) private var store
    @Environment(AppState.self) private var app
    var body: some View {
        let nextChallenge = ContentRepository.challenges.first { store.progress.completedLessons.contains($0.l) && !store.progress.buildings.contains($0.id) }
        let nextLesson = ContentRepository.lessons.first { !store.progress.completedLessons.contains($0.id) } ?? ContentRepository.lessons[4]
        QuestPage {
            HStack { Label("MemoryQuest",systemImage:"brain").font(.headline).foregroundStyle(.purple); Spacer(); Button { app.path.append(.settings) } label: { Image(systemName:"slider.horizontal.3").padding(12).background(.white,in:Circle()) }.accessibilityLabel("Settings") }
            PageTitle(text:"Morning, \(store.progress.name)")
            Text("A little practice. Something to build on.").font(.subheadline).foregroundStyle(AppTheme.muted)
            CityIllustration(buildings:store.progress.buildings) { app.path.append(.building($0)) }
            Button { app.path.append(.city(false)) } label: {
                QuestCard { HStack { Text("My City").font(.title3.bold()); Spacer(); Image(systemName:"chevron.right") }; Text("\(store.progress.buildings.count) of 10 buildings · \(store.progress.buildings.count*10)% built").foregroundStyle(AppTheme.muted); ProgressView(value:Double(store.progress.buildings.count),total:10) }
            }.buttonStyle(.plain)
            HStack { Text(nextChallenge == nil ? "Your next lesson" : "Ready to practise").font(.title3.bold()); Spacer(); Text("\(store.progress.completion)% journey").font(.caption).foregroundStyle(AppTheme.muted) }
            QuestCard {
                Text("Lesson \((nextChallenge?.l ?? nextLesson.id)+1) · \(nextChallenge == nil ? "4–6 min" : "Challenge ready")").font(.caption).foregroundStyle(AppTheme.muted)
                Text(nextChallenge?.title ?? nextLesson.short).font(.title2.bold())
                Text((nextChallenge?.desc ?? nextLesson.desc).replacingOccurrences(of:"CS", with:store.progress.subject == .biology ? "Biology" : "CS")).font(.subheadline).foregroundStyle(AppTheme.muted)
                QuestButton(title:store.progress.buildings.count == 10 ? "Review my learning" : "Continue Learning") {
                    if store.progress.buildings.count == 10 { app.navigate(.progress) }
                    else if let challenge = nextChallenge { app.path.append(.challenge(challenge.id)) }
                    else { app.path.append(.lesson(nextLesson.id)) }
                }
            }
            Text("Recent achievements").font(.title3.bold())
            QuestCard {
                if let attempt = store.progress.attempts.last {
                    Label(store.attempts(attempt.challengeID).first?.id == attempt.id ? "\(ContentRepository.challenges[attempt.challengeID].building) constructed" : "\(ContentRepository.challenges[attempt.challengeID].title) practised",systemImage:"rosette").font(.headline)
                    Text(attempt.date.formatted(date:.abbreviated,time:.omitted)).font(.caption)
                } else { Text("Your story starts here."); Text("Complete your first challenge to build the Library.").font(.caption).foregroundStyle(AppTheme.muted) }
            }
        }
    }
}
