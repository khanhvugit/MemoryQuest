import SwiftUI

struct SettingsView: View {
    @Environment(ProgressStore.self) private var store
    @Environment(AppState.self) private var app
    @State private var name = ""
    @State private var confirmReset = false
    var body: some View {
        @Bindable var app = app
        QuestPage {
            PageTitle(text:"Make it yours")
            QuestCard {
                Label("City atmosphere", systemImage: app.appearance.symbol)
                    .font(.headline)
                Picker("Appearance", selection: $app.appearance) {
                    ForEach(AppAppearance.allCases) { appearance in
                        Label(appearance.title, systemImage: appearance.symbol)
                            .tag(appearance)
                    }
                }
                .pickerStyle(.segmented)
                Text("Night mode changes the entire app palette and lights the city after dark.")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.muted)
            }
            Text("Your name")
            AnswerField(text:$name,prompt:"Your name")
            QuestButton(title:"Save name") {
                store.progress.name=String(name.trimmingCharacters(in:.whitespacesAndNewlines).prefix(24))
                if store.progress.name.isEmpty { store.progress.name="Alex" }
                store.save(); app.navigate(.home)
            }
            QuestCard {
                Text("Completed city preview").font(.headline)
                QuestButton(title:"Preview completed city",secondary:true) { app.path.append(.city(true)) }
            }
            QuestCard {
                Text("Start fresh").font(.headline)
                QuestButton(title:"Reset Progress",secondary:true) { confirmReset=true }
            }
        }.navigationTitle("Settings").onAppear { name=store.progress.name }
            .confirmationDialog("Start a fresh city?",isPresented:$confirmReset,titleVisibility:.visible) {
                Button("Reset Progress",role:.destructive) { store.reset(); app.navigate(.home) }
                Button("Keep my progress",role:.cancel) { }
            } message: { Text("Your lesson progress, challenge results, reviews, and buildings will be cleared from this device.") }
    }
}

#if DEBUG
#Preview("SettingsView") {
    PreviewScreen() { SettingsView() }
}
#endif
