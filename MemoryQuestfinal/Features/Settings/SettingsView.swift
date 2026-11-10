import SwiftUI

struct SettingsView: View {
    @Environment(ProgressStore.self) private var store
    @Environment(AppState.self) private var app
    @State private var name = ""
    @State private var confirmReset = false
    var body: some View {
        QuestPage {
            PageTitle(text:"Make it yours")
            Text("Your name")
            AnswerField(text:$name,prompt:"Your name")
            QuestButton(title:"Save name") {
                store.progress.name=String(name.trimmingCharacters(in:.whitespacesAndNewlines).prefix(24))
                if store.progress.name.isEmpty { store.progress.name="Alex" }
                store.save(); app.navigate(.home)
            }
            SubjectPicker()
            QuestCard {
                Text("Completed city preview").font(.headline)
                Text("Explore all ten buildings without changing your lesson, challenge, or score history.").font(.subheadline).foregroundStyle(AppTheme.muted)
                QuestButton(title:"Preview completed city",secondary:true) { app.path.append(.city(true)) }
            }
            QuestCard {
                Text("Start fresh").font(.headline)
                Text("Reset lessons, scores, and buildings on this device.").font(.subheadline).foregroundStyle(AppTheme.muted)
                QuestButton(title:"Reset Progress",secondary:true) { confirmReset=true }
            }
            Text("Progress is kept on this device. The app works offline.").font(.caption).foregroundStyle(AppTheme.muted)
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
