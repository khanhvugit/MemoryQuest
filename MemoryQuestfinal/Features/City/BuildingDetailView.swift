import SwiftUI

struct BuildingDetailView: View {
    let id: Int
    var preview = false
    @Environment(ProgressStore.self) private var store
    @Environment(AppState.self) private var app
    var body: some View {
        let c=ContentRepository.challenges[id]
        let attempts=store.attempts(id,subject:store.progress.subject)
        let built=store.progress.buildings.contains(id)
        QuestPage {
            BuildingArt(id:id,empty:!built && !preview).frame(height:190)
            Text(c.building).font(.title.bold()).frame(maxWidth:.infinity)
            PageTitle(text:c.title)
            Text("Lesson \(c.l+1) · \(ContentRepository.lessons[c.l].title)").font(.subheadline).foregroundStyle(AppTheme.muted)
            SubjectPicker()
            QuestCard {
                Text(built ? "Your learning achievement" : preview ? "Completed city preview" : "This plot is waiting for you").font(.headline)
                Text(ContentRepository.lessons[c.l].summary).font(.subheadline)
                if let last=attempts.last {
                    MetricRow(title:"First constructed",value:store.attempts(id).first?.date.formatted(date:.abbreviated,time:.omitted) ?? "")
                    MetricRow(title:"Previous score",value:"\(last.score)%")
                    MetricRow(title:"Best score",value:"\(attempts.map(\.score).max() ?? 0)%")
                    MetricRow(title:"Attempts",value:"\(attempts.count)")
                } else { Text(built ? "No attempts in \(store.progress.subject.title) yet. The building is shared across subjects." : preview ? "This is a preview building. Complete \(c.title) to construct it in your real city." : "Complete \(c.title) to construct your \(c.building).").font(.subheadline).foregroundStyle(AppTheme.muted) }
            }
            if !attempts.isEmpty { QuestButton(title:"Previous results",secondary:true) { app.path.append(.history(id)) } }
            QuestButton(title:store.progress.completedLessons.contains(c.l) ? (attempts.isEmpty ? "Preview challenge" : "Replay Challenge") : "Go to lesson") { app.path.append(store.progress.completedLessons.contains(c.l) ? .challenge(id) : .lesson(c.l)) }
            if store.progress.completedLessons.contains(c.l) { QuestButton(title:"Review lesson",secondary:true) { app.path.append(.lesson(c.l)) } }
        }.navigationTitle("Building details")
    }
}
