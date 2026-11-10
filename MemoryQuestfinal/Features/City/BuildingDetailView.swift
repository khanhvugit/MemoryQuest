import SwiftUI

struct BuildingDetailView: View {
    let id: Int
    @Environment(ProgressStore.self) private var store
    @Environment(AppState.self) private var app
    var body: some View {
        let c=ContentRepository.challenges[id]
        let attempts=store.attempts(id,subject:store.progress.subject)
        let built=store.progress.buildings.contains(id)
        QuestPage {
            BuildingDetailHeader(
                challenge: c,
                difficulty: attempts.last?.difficulty ?? .easy
            )
            HStack {
                Text("Subject").font(.headline)
                Spacer()
                LessonSubjectMenu()
            }
            QuestCard {
                Text(built ? "Your learning achievement" : "This plot is waiting for you").font(.headline)
                Text(ContentRepository.lessons[c.l].summary).font(.subheadline)
                if let last=attempts.last {
                    Divider()
                    if let firstPassed = store.attempts(id).first(where: { $0.passed }) {
                        MetricRow(title: "First constructed", value: firstPassed.date.formatted(date: .abbreviated, time: .omitted))
                    }
                    MetricRow(title:"Previous score",value:"\(last.score)%")
                    MetricRow(title:"Best score",value:"\(attempts.map(\.score).max() ?? 0)%")
                    MetricRow(title:"Attempts",value:"\(attempts.count)", showsDivider: false)
                } else { Text(built ? "No attempts in \(store.progress.subject.title) yet. The building is shared across subjects." : "Complete \(c.title) to construct your \(c.building).").font(.subheadline).foregroundStyle(AppTheme.muted) }
            }
            if !attempts.isEmpty { QuestButton(title:"Previous results",secondary:true) { app.path.append(.history(id)) } }
            QuestButton(title:store.progress.completedLessons.contains(c.l) ? (attempts.isEmpty ? "Preview challenge" : "Replay Challenge") : "Go to lesson") { app.path.append(store.progress.completedLessons.contains(c.l) ? .challenge(id) : .lesson(c.l)) }
        }.navigationTitle("Building details")
    }
}

private struct BuildingDetailHeader: View {
    let challenge: Challenge
    let difficulty: Difficulty

    var body: some View {
        VStack(spacing: 10) {
            VStack(spacing: 10) {
                BuildingArt(id: challenge.id)
                    .frame(width: 110, height: 110)
                Text(challenge.building)
                    .font(.title3.bold())
                    .foregroundStyle(BuildingArt.accent(for: challenge.id))
                    .multilineTextAlignment(.center)
            }
            .padding(20)
            .frame(width: 184)
            .frame(minHeight: 184)
            .background(
                BuildingArt.assets[challenge.id] == "shop-2"
                    ? Color(hex: "EFC2FA")
                    : BuildingArt.accent(for: challenge.id).opacity(0.2),
                in: RoundedRectangle(cornerRadius: 8)
            )
            Text(challenge.title)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text(difficulty.rawValue)
                .font(.caption)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.65), in: RoundedRectangle(cornerRadius: 5))
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 12)
    }
}

#if DEBUG
#Preview("BuildingDetailView") {
    PreviewScreen(results: true) { BuildingDetailView(id: 0) }
}
#endif
