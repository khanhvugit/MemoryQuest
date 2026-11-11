import SwiftUI

struct CityView: View {
    let preview: Bool
    var newBuildingID: Int? = nil
    @Environment(ProgressStore.self) private var store
    @Environment(AppState.self) private var app
    var body: some View {
        let built=preview ? Set(0..<10) : store.progress.buildings
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                CityIllustration(buildings: built, newBuildingID: preview ? nil : newBuildingID) { app.path.append(.building($0)) }
                VStack(alignment: .leading, spacing: 20) {
                    ProgressView(value: Double(built.count), total: 10)
                    if preview {
                        QuestButton(title: "Return to my real city", secondary: true) {
                            app.path.removeLast()
                            app.path.append(.city(false))
                        }
                    }
                    if built.count == 10 && !preview {
                        QuestCard {
                            Text("Look how far you’ve come!").font(.title2.bold())
                            QuestButton(title: "See my learning journey") { app.navigate(.progress) }
                        }
                    }
                    Text(preview ? "The complete district guide" : built.isEmpty ? "Your first foundations" : "My buildings")
                        .font(.title3.bold())
                    if built.isEmpty {
                        QuestButton(title: "Start the first lesson") { app.path.append(.lesson(0)) }
                    }
                    ForEach(ContentRepository.challenges.filter { built.contains($0.id) }) { c in
                        Button { app.path.append(.building(c.id)) } label: {
                            QuestCard {
                                HStack {
                                    BuildingArt(id: c.id).frame(width: 70, height: 75)
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(c.building).font(.headline)
                                        Text(c.title).font(.subheadline).foregroundStyle(AppTheme.muted)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 22)
            }
            .padding(.top, 42)
            .padding(.bottom, 28)
            .frame(maxWidth: 644)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .background(AppTheme.background)
        .navigationTitle(preview ? "City Preview" : "My City")
        .toolbarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    app.navigate(.home)
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
                .accessibilityLabel("Back to Home")
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
            CelebrationPage {
                VStack(spacing: 50) {
                    VStack(spacing: 12) {
                        BuildingArt(id: c.id)
                            .frame(height: 150)
                        Text(c.building)
                            .font(.largeTitle.bold())
                            .foregroundStyle(BuildingArt.accent(for: c.id))
                            .multilineTextAlignment(.center)
                    }
                    .padding(32)
                    .frame(maxWidth: 276, minHeight: 276)
                    .background(
                        BuildingArt.assets[c.id] == "shop-2"
                            ? Color(hex: "EFC2FA")
                            : BuildingArt.accent(for: c.id).opacity(0.2),
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                    .scaleEffect(appeared ? 1 : 0.65)
                    .opacity(appeared ? 1 : 0)

                    Text(isNew ? "New Building Unlocked!" : "Practice Complete!")
                        .font(.largeTitle.bold())
                        .tracking(-1)
                        .multilineTextAlignment(.center)

                    CelebrationButton(title: isNew ? "Add to My City" : "View My City") {
                        app.navigate(.home)
                        app.path.append(isNew ? .cityAddition(c.id) : .city(false))
                    }
                }
            }
            .onAppear {
                withAnimation(reduceMotion ? nil : .spring(duration: 0.7, bounce: 0.3)) {
                    appeared = true
                }
            }
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
