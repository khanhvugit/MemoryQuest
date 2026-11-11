import SwiftUI
import UIKit

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
        }
        .background {
            ResetProgressAlert(isPresented: $confirmReset) {
                store.reset()
                app.navigate(.home)
            }
        }
        .navigationTitle("Settings")
        .onAppear { name = store.progress.name }
    }
}

private struct ResetProgressAlert: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let reset: () -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ controller: UIViewController, context: Context) {
        guard isPresented, controller.viewIfLoaded?.window != nil,
              controller.presentedViewController == nil else { return }

        let alert = UIAlertController(
            title: String(localized: "Start a fresh city?"),
            message: String(localized: "Your lesson progress, challenge results, reviews, and buildings will be cleared from this device."),
            preferredStyle: .alert
        )
        // The dark system appearance keeps the white cancel action legible in either app theme.
        alert.overrideUserInterfaceStyle = .dark
        alert.traitOverrides.accessibilityContrast = .high
        alert.view.tintColor = .white
        alert.addAction(UIAlertAction(title: String(localized: "Keep my progress"), style: .cancel) { _ in
            isPresented = false
        })
        alert.addAction(UIAlertAction(title: String(localized: "Reset Progress"), style: .destructive) { _ in
            isPresented = false
            reset()
        })
        controller.present(alert, animated: true)
    }
}

#if DEBUG
#Preview("SettingsView") {
    PreviewScreen() { SettingsView() }
}
#endif
