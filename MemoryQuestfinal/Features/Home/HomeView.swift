import SwiftUI

struct HomeView: View {
    @Environment(ProgressStore.self) private var store
    @Environment(AppState.self) private var app

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Morning, \(store.progress.name)")
                        .font(.largeTitle.bold())
                    Spacer()
                    Button { app.path.append(.settings) } label: {
                        Image(systemName: "slider.horizontal.3")
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Settings")
                }
                .padding(.horizontal, 28)
                .padding(.top, 28)

                CityIllustration(buildings: store.progress.buildings) {
                    app.path.append(.building($0))
                }
                .padding(.top, 14)

                HomeCityProgress(count: store.progress.buildings.count) {
                    app.path.append(.city(false))
                }
                .padding(.horizontal, 22)
                .padding(.top, -12)

                HomeSuggestions()
                    .padding(.horizontal, 22)
                    .padding(.top, 24)
            }
            .padding(.bottom, 28)
            .frame(maxWidth: 644)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .background(AppTheme.background)
    }
}

private struct HomeCityProgress: View {
    let count: Int
    let open: () -> Void

    var body: some View {
        Button(action: open) {
            QuestCard {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("My City").font(.title2.bold())
                        Text("\(count * 10)%").font(.title3).foregroundStyle(AppTheme.muted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                ProgressView(value: Double(count), total: 10)
                    .tint(Color("ProgressFill"))
                    .padding(.vertical, 4)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("My City, \(count * 10) percent complete")
    }
}

private struct HomeSuggestions: View {
    @Environment(ProgressStore.self) private var store
    @Environment(AppState.self) private var app

    var body: some View {
        let challenge = ContentRepository.challenges.first {
            store.progress.completedLessons.contains($0.l) && !store.progress.buildings.contains($0.id)
        }
        let lesson = ContentRepository.lessons.first {
            !store.progress.completedLessons.contains($0.id)
        } ?? ContentRepository.lessons[4]
        VStack(alignment: .leading, spacing: 10) {
            Text("Suggestions").font(.title2.bold()).padding(.horizontal, 4)
            Button {
                if store.progress.buildings.count == 10 {
                    app.navigate(.progress)
                } else if let challenge {
                    app.path.append(.challenge(challenge.id))
                } else {
                    app.path.append(.lesson(lesson.id))
                }
            } label: {
                QuestCard {
                    HStack(spacing: 16) {
                        Image(systemName: "play")
                            .font(.title.weight(.light))
                            .foregroundStyle(AppTheme.coral)
                            .frame(width: 58, height: 58)
                            .background(Color("AccentCoralSoft"), in: RoundedRectangle(cornerRadius: 9))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(store.progress.buildings.count == 10 ? "Learning progress" : "Lesson \((challenge?.l ?? lesson.id) + 1)")
                                .font(.title3.weight(.medium))
                            Text(store.progress.buildings.count == 10 ? "Review my learning" : challenge?.title ?? lesson.short)
                                .font(.body.weight(.medium))
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }
}
