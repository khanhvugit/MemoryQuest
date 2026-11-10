import SwiftUI

enum AppTheme {
    static let background = Color("AppBackground")
    static let coral = Color("AccentColor")
    static let ink = Color("TextPrimary")
    static let muted = Color("TextSecondary")
    static let line = Color("Border")
    static let radius: CGFloat = 12
    static let padding: CGFloat = 20
}
extension Color {
    init(hex: String) {
        let value = UInt64(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0
        self.init(.sRGB, red: Double((value >> 16) & 255) / 255, green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255, opacity: 1)
    }
}
struct QuestButton: View {
    let title: String
    var secondary = false
    var disabled = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(.body.weight(.semibold)).frame(maxWidth: .infinity).padding(.vertical, 14).padding(.horizontal, 12)
                .foregroundStyle(secondary ? AppTheme.ink : .white)
                .background(secondary ? Color.white : AppTheme.coral, in: RoundedRectangle(cornerRadius: 11))
                .overlay(RoundedRectangle(cornerRadius: 11).stroke(secondary ? AppTheme.line : .clear))
        }.buttonStyle(.plain).disabled(disabled).opacity(disabled ? 0.45 : 1)
    }
}
struct QuestCard<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View { VStack(alignment: .leading, spacing: 12) { content }.frame(maxWidth: .infinity, alignment: .leading).padding(18).background(Color("CardBackground"), in: RoundedRectangle(cornerRadius: AppTheme.radius)) }
}
struct QuestPage<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 20) { content }.frame(maxWidth: 600).frame(maxWidth: .infinity).padding(AppTheme.padding) }
            .scrollIndicators(.hidden).scrollDismissesKeyboard(.interactively).background(AppTheme.background)
    }
}
struct PageTitle: View {
    let text: String
    var body: some View { Text(text).font(.largeTitle.weight(.bold)).tracking(-1).fixedSize(horizontal: false, vertical: true) }
}
struct SubjectPicker: View {
    @Environment(ProgressStore.self) private var store
    var body: some View {
        @Bindable var store = store
        Picker("Subject", selection: $store.progress.subject) { ForEach(Subject.allCases) { Text($0.title).tag($0) } }.pickerStyle(.segmented).onChange(of: store.progress.subject) { store.save() }
    }
}
struct FeedbackView: View {
    let text: String
    let correct: Bool
    var body: some View { Text(text).frame(maxWidth: .infinity, alignment: .leading).padding(16).background(correct ? Color.green.opacity(0.09) : Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12)).accessibilityAddTraits(.updatesFrequently) }
}
struct AnswerField: View {
    @Binding var text: String
    var prompt = "Your answer"
    var multiline = false
    var body: some View {
        TextField(prompt, text: $text, axis: multiline ? .vertical : .horizontal).lineLimit(multiline ? 4...8 : 1...1)
            .textInputAutocapitalization(.never).autocorrectionDisabled().padding(14)
            .background(.white, in: RoundedRectangle(cornerRadius: 10)).overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.line))
    }
}

#if DEBUG
#Preview("QuestButton") {
    PreviewScreen() { QuestButton(title: "Start", action: {}) }
}

#Preview("QuestCard") {
    PreviewScreen() { QuestCard { Text("Your learning journey") } }
}

#Preview("QuestPage") {
    PreviewScreen() { QuestPage { PageTitle(text: "Progress") } }
}

#Preview("PageTitle") {
    PreviewScreen() { PageTitle(text: "Challenges") }
}

#Preview("SubjectPicker") {
    PreviewScreen() { SubjectPicker() }
}

#Preview("FeedbackView") {
    PreviewScreen() { FeedbackView(text: "You retrieved it!", correct: true) }
}

#Preview("AnswerField") {
    @Previewable @State var answer = ""
    PreviewScreen() { AnswerField(text: $answer) }
}
#endif
