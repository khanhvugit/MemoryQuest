import SwiftUI

struct ChallengeListView: View {
    @Environment(ProgressStore.self) private var store
    var body: some View {
        QuestPage {
            HStack(spacing: 8) {
                Text("Challenges").font(.largeTitle.bold()).lineLimit(1).minimumScaleFactor(0.8)
                Spacer(minLength: 0)
                LessonSubjectMenu()
            }.padding(.top, 8)
            ForEach(ContentRepository.lessons) { lesson in
                HStack { Text("Lesson \(lesson.id+1) · \(lesson.short)").font(.headline); Spacer(); Text("\(store.progress.buildings.filter { $0/2 == lesson.id }.count)/2").font(.caption).padding(8).background(AppTheme.line,in:RoundedRectangle(cornerRadius:7)) }.padding(.top,12)
                ForEach(ContentRepository.challenges.filter { $0.l == lesson.id }) { challenge in ChallengeRow(challenge:challenge) }
            }
        }
    }
}
struct ChallengeRow: View {
    let challenge: Challenge
    @Environment(ProgressStore.self) private var store
    @Environment(AppState.self) private var app
    var body: some View {
        let locked = !store.progress.completedLessons.contains(challenge.l)
        let latest = store.attempts(challenge.id,subject:store.progress.subject).last
        Button { app.path.append(.challenge(challenge.id)) } label: {
            QuestCard {
                HStack(spacing:13) {
                    BuildingArt(id:challenge.id).padding(12).frame(width:70,height:70).background(BuildingArt.accent(for: challenge.id).opacity(0.12),in:RoundedRectangle(cornerRadius:12))
                    VStack(alignment:.leading,spacing:6) {
                        Text(challenge.title).font(.headline)
                        Text(challenge.desc.replacingOccurrences(of:"CS",with:store.progress.subject == .biology ? "Biology" : "CS")).font(.subheadline).foregroundStyle(AppTheme.muted)
                        if !locked, let latest {
                            Text("Replay · Last \(latest.score)%").font(.caption).foregroundStyle(AppTheme.muted)
                        }
                    }
                    Spacer(minLength:0); Image(systemName:locked ? "lock" : "chevron.right").foregroundStyle(BuildingArt.accent(for: challenge.id))
                }
            }
        }.buttonStyle(.plain)
    }
}
struct ChallengeIntroView: View {
    let id: Int
    @Environment(ProgressStore.self) private var store
    @Environment(AppState.self) private var app
    @State private var difficulty = Difficulty.easy
    var body: some View {
        let c = ContentRepository.challenges[id]
        let attempts = store.attempts(id,subject:store.progress.subject)
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
            QuestCard {
                VStack(alignment: .leading, spacing: 6) {
                    Text(c.title).font(.title2.bold())
                    Text("Complete this challenge to unlock this building")
                        .font(.caption).foregroundStyle(AppTheme.muted)
                }
                BuildingArt(id: id)
                    .frame(height: 130)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                Text(c.desc.replacingOccurrences(
                    of: "CS",
                    with: store.progress.subject == .biology ? "Biology" : "CS"
                ))
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
                Divider()
                MetricRow(title: "Time", value: c.mins)
                MetricRow(title: "Activities", value: activityCount)
                MetricRow(title: "Pass requirement", value: "90% accuracy", showsDivider: false)
            }
            if store.progress.completedLessons.contains(c.l) {
                Text("Choose difficulty").font(.title3.weight(.semibold))
                    .padding(.top, 6)
                DifficultySelector(selection: $difficulty)
            } else {
                Text("Start with Lesson \(c.l+1) to learn the strategy.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }
            }
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, AppTheme.padding)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .background(AppTheme.background)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 12) {
                if store.progress.completedLessons.contains(c.l) {
                    QuestButton(title: attempts.isEmpty ? "Start" : "Replay challenge") {
                        app.path.append(.session(id, store.progress.subject, difficulty))
                    }
                } else {
                    QuestButton(title: "Learn \(ContentRepository.lessons[c.l].short)") {
                        app.path.append(.lesson(c.l))
                    }
                }
                if !attempts.isEmpty {
                    QuestButton(title: "Previous results", secondary: true) {
                        app.path.append(.history(id))
                    }
                }
            }
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, AppTheme.padding)
            .padding(.vertical, 16)
            .background(AppTheme.background)
        }
        .navigationTitle("Challenge")
    }

    private var activityCount: String {
        "\(difficulty.questionCount) questions"
    }
}

struct DifficultySelector: View {
    @Binding var selection: Difficulty

    var body: some View {
        HStack(spacing: 12) {
            ForEach(Difficulty.allCases) { difficulty in
                Button { selection = difficulty } label: {
                    Text(difficulty.rawValue)
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .foregroundStyle(selection == difficulty ? AppTheme.coral : AppTheme.ink)
                        .background(selection == difficulty ? AppTheme.coral.opacity(0.12) : AppTheme.line.opacity(0.5),
                                    in: RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selection == difficulty ? AppTheme.coral : .clear)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == difficulty ? .isSelected : [])
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Difficulty")
    }
}

#if DEBUG
#Preview("ChallengeListView") {
    PreviewScreen() { ChallengeListView() }
}

#Preview("ChallengeIntroView") {
    PreviewScreen() { ChallengeIntroView(id: 1) }
}

#Preview("ChallengeRow") {
    PreviewScreen() { ChallengeRow(challenge: ContentRepository.challenges[1]) }
}

#Preview("DifficultySelector") {
    @Previewable @State var difficulty = Difficulty.easy
    PreviewScreen() { DifficultySelector(selection: $difficulty) }
}

#Preview("Challenge locked") {
    PreviewScreen() { ChallengeIntroView(id: 2) }
}
#endif
