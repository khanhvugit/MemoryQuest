import SwiftUI

struct CityView: View {
    let preview: Bool
    @Environment(ProgressStore.self) private var store
    @Environment(AppState.self) private var app
    var body: some View {
        let built=preview ? Set(0..<10) : store.progress.buildings
        QuestPage {
            HStack { PageTitle(text:"My City"); Spacer(); Button { app.path.append(.settings) } label: { Image(systemName:"slider.horizontal.3") }.accessibilityLabel("Settings") }
            Text(preview ? "Completed city preview · Your progress is unchanged." : "\(built.count) buildings. Every one tells a learning story.").font(.subheadline).foregroundStyle(AppTheme.muted)
            CityIllustration(buildings:built) { app.path.append(.building($0)) }
            ProgressView(value:Double(built.count),total:10)
            Text("Tap a building or an empty plot to explore.").font(.caption).foregroundStyle(AppTheme.muted)
            if preview { QuestButton(title:"Return to my real city",secondary:true) { app.path.removeLast(); app.path.append(.city(false)) } }
            if built.count == 10 && !preview {
                QuestCard { Text("Look how far you’ve come!").font(.title2.bold()); Text("Every building represents a challenge you completed and a memory strategy you practised."); QuestButton(title:"See my learning journey") { app.navigate(.progress) } }
            }
            Text(preview ? "The complete district guide" : built.isEmpty ? "Your first foundations" : "My buildings").font(.title3.bold())
            if built.isEmpty {
                QuestCard { Text("Your Library starts with Word Flash.").font(.headline); Text("Learn active recall, complete the challenge, and watch your first building appear.").font(.subheadline); QuestButton(title:"Start the first lesson") { app.path.append(.lesson(0)) } }
            }
            ForEach(ContentRepository.challenges.filter { built.contains($0.id) }) { c in
                Button { app.path.append(.building(c.id)) } label: {
                    QuestCard { HStack { BuildingArt(id:c.id).frame(width:70,height:75); VStack(alignment:.leading,spacing:6) { Text(c.building).font(.headline); Text(c.title).font(.subheadline).foregroundStyle(AppTheme.muted); if preview { Text("Completed city preview").font(.caption) } }; Spacer(); Image(systemName:"chevron.right") } }
                }.buttonStyle(.plain)
            }
        }
    }
}
struct BuildingRewardView: View {
    let attemptID: UUID
    let isNew: Bool
    @Environment(ProgressStore.self) private var store
    @Environment(AppState.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    var body: some View {
        if let attempt=store.progress.attempts.first(where:{ $0.id == attemptID }) {
            let c=ContentRepository.challenges[attempt.challengeID]
            QuestPage {
                BuildingArt(id:c.id).frame(height:240).scaleEffect(appeared ? 1 : 0.65).offset(y:appeared ? 0 : -28).opacity(appeared ? 1 : 0)
                Text(c.building).font(.title.bold()).frame(maxWidth:.infinity)
                PageTitle(text:isNew ? "New Building Unlocked!" : "Practice Complete!")
                Text(isNew ? "Your \(c.building) is now part of your city." : "Your result is saved. This building keeps its place in your city.").foregroundStyle(AppTheme.muted)
                Text("\(c.title)\n\(ContentRepository.lessons[c.l].short)")
                QuestButton(title:isNew ? "Add to My City" : "View My City") { app.navigate(.home); app.path.append(.city(false)) }
                Text("\(store.progress.buildings.count) of 10 buildings constructed").font(.caption).foregroundStyle(AppTheme.muted)
            }.navigationBarBackButtonHidden().onAppear { withAnimation(reduceMotion ? nil : .spring(duration:0.7,bounce:0.3)) { appeared=true } }
        }
    }
}

#if DEBUG
#Preview("CityView") {
    PreviewScreen() { CityView(preview: true) }
}

#Preview("BuildingRewardView") {
    PreviewScreen(results: true) { BuildingRewardView(attemptID: PreviewData.attempt.id, isNew: true) }
}
#endif
