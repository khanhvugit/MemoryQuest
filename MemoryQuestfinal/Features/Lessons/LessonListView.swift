import SwiftUI

struct LessonListView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Lessons").font(.largeTitle.bold())
                    Spacer(minLength: 8)
                    LessonSubjectMenu()
                }
                ForEach(ContentRepository.lessons) { lesson in
                    Button { app.path.append(.lesson(lesson.id)) } label: {
                        LessonListCard(lesson: lesson)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 28)
            .padding(.bottom, 96)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .background(AppTheme.background)
    }
}

struct LessonListCard: View {
    let lesson: Lesson

    var body: some View {
        HStack(spacing: 14) {
            LessonIcon(lesson: lesson, size: 86)
            VStack(alignment: .leading, spacing: 2) {
                Text("Lesson \(lesson.id + 1)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
                Text(LessonPresentation.title(for: lesson))
                    .font(.title3.bold())
                Text(lesson.desc)
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right")
                .font(.body.weight(.semibold))
                .accessibilityHidden(true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 114, alignment: .leading)
        .background(Color("CardBackground"), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}

enum LessonPresentation {
    static func title(for lesson: Lesson) -> String {
        switch lesson.id {
        case 0: "Active Recalling"
        case 2: "Association"
        default: lesson.short
        }
    }

    static func symbol(for lesson: Lesson) -> String {
        switch lesson.id {
        case 0: "brain.head.profile"
        case 1: "square.grid.2x2"
        case 2: "link"
        case 3: "clock.arrow.circlepath"
        default: "bubble.left.and.bubble.right"
        }
    }

    static func background(for lesson: Lesson) -> Color {
        switch lesson.id {
        case 0: Color(hex: "f7e3fd")
        case 1: Color(hex: "b7eb9d")
        case 2: Color(hex: "9ab8f5")
        case 3: Color(hex: "ffe3e6")
        default: Color(hex: "fff299")
        }
    }

    static func foreground(for lesson: Lesson) -> Color {
        switch lesson.id {
        case 0: Color(hex: "9f32c0")
        case 1: Color(hex: "457d2e")
        case 2: Color(hex: "003cc5")
        case 3: AppTheme.coral
        default: Color(hex: "ce8d00")
        }
    }
}

struct LessonIcon: View {
    let lesson: Lesson
    var size: CGFloat = 90

    var body: some View {
        Image(systemName: LessonPresentation.symbol(for: lesson))
            .font(.system(size: size * 0.42, weight: .light))
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(LessonPresentation.foreground(for: lesson))
        .frame(width: size, height: size)
        .background(LessonPresentation.background(for: lesson), in: RoundedRectangle(cornerRadius: 9))
        .accessibilityHidden(true)
    }
}

struct LessonIntroView: View {
    let id: Int
    @Environment(ProgressStore.self) private var store
    @Environment(AppState.self) private var app

    var body: some View {
        let lesson = ContentRepository.lessons[id]
        ScrollView {
            VStack(spacing: 0) {
                LessonIcon(lesson: lesson, size: 226)
                    .padding(.top, 32)
                Text(LessonPresentation.title(for: lesson))
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                    .padding(.top, 28)
                    .padding(.bottom, 38)
                LessonOutline(lesson: lesson)
                Button {
                    app.path.append(.reader(id))
                } label: {
                    Text(store.progress.completedLessons.contains(id) ? "Review lesson" :
                            store.progress.lessonSteps[id, default: 0] > 0 ? "Continue lesson" : "Start lesson")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 56)
                        .background(AppTheme.coral, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .padding(.top, 20)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 32)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .background(AppTheme.background)
        .navigationTitle("Lesson \(id + 1)")
    }
}

private struct LessonOutline: View {
    let lesson: Lesson
    private let recallSteps = [
        "Discover the problem",
        "Understand the technique",
        "How to active recall?",
        "Try with guidance",
        "Apply it to your studies"
    ]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(lesson.pages.indices, id: \.self) { index in
                HStack(alignment: .firstTextBaseline, spacing: 16) {
                    Text(lesson.id == 0 && index < recallSteps.count ? recallSteps[index] : lesson.pages[index].title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(String(format: "%02d", index + 1))
                        .monospacedDigit()
                }
                .font(.body)
                .padding(.vertical, 12)
                if index < lesson.pages.count - 1 {
                    Divider()
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(Color("CardBackground"), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct LessonSubjectMenu: View {
    @Environment(ProgressStore.self) private var store

    var body: some View {
        @Bindable var store = store
        Menu {
            Picker("Subject", selection: $store.progress.subject) {
                ForEach(Subject.allCases) { Text($0.title).tag($0) }
            }
        } label: {
            HStack(spacing: 6) {
                Text(store.progress.subject.title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
            }
            .font(.subheadline)
            .foregroundStyle(AppTheme.ink)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .accessibilityLabel("Subject")
        .accessibilityValue(store.progress.subject.title)
        .onChange(of: store.progress.subject) { store.save() }
    }
}

#if DEBUG
#Preview("LessonListView") {
    PreviewScreen() { LessonListView() }
}

#Preview("LessonListCard") {
    PreviewScreen() { LessonListCard(lesson: ContentRepository.lessons[0]) }
}

#Preview("LessonIcon") {
    PreviewScreen() { LessonIcon(lesson: ContentRepository.lessons[0]) }
}

#Preview("LessonIntroView") {
    PreviewScreen() { LessonIntroView(id: 0) }
}

#Preview("LessonOutline") {
    PreviewScreen() { LessonOutline(lesson: ContentRepository.lessons[0]) }
}

#Preview("LessonSubjectMenu") {
    PreviewScreen() { LessonSubjectMenu() }
}
#endif
