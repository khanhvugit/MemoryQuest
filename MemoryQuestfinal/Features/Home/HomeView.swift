import SwiftUI

struct HomeView: View {
    @Environment(ProgressStore.self) private var store
    @Environment(AppState.self) private var app
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("\(colorScheme == .dark ? "Evening" : "Morning"), \(store.progress.name)")
                        .font(.largeTitle.bold())
                    Spacer()
                    Button { app.path.append(.settings) } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundStyle(AppTheme.ink)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: Circle())
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
                .padding(.top, 8)

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

    private var total: Int { ContentRepository.challenges.count }
    private var completedCount: Int { min(max(count, 0), total) }
    private var percentage: Int {
        total > 0 ? Int((Double(completedCount) / Double(total) * 100).rounded()) : 0
    }

    var body: some View {
        Button(action: open) {
            QuestCard {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("My City").font(.title2.bold())
                        Text("\(percentage)%").font(.title3).foregroundStyle(AppTheme.muted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                ProgressView(value: Double(completedCount), total: Double(max(total, 1)))
                    .progressViewStyle(.linear)
                    .tint(Color("ProgressFill"))
                    .accessibilityLabel("Buildings constructed")
                    .accessibilityValue("\(completedCount) of \(total)")
                    .padding(.vertical, 4)
            }
            .contentShape(RoundedRectangle(cornerRadius: AppTheme.radius))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("My City, \(percentage) percent complete")
    }
}

private struct HomeSuggestions: View {
    @Environment(ProgressStore.self) private var store
    @Environment(AppState.self) private var app

    var body: some View {
        if let lesson = ContentRepository.lessons.first(where: {
            !store.progress.completedLessons.contains($0.id)
        }) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Ready to practice")
                    .font(.title2.bold())
                    .padding(.horizontal, 4)
                Button {
                    app.path.append(.lesson(lesson.id))
                } label: {
                    LessonListCard(lesson: lesson)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#if DEBUG
#Preview("HomeView") {
    PreviewScreen() { HomeView() }
}

#Preview("HomeCityProgress") {
    PreviewScreen() { HomeCityProgress(count: 3, open: {}) }
}

#Preview("HomeSuggestions") {
    PreviewScreen() { HomeSuggestions() }
}
#endif
