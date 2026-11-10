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
            .padding(.bottom, 20)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .background(AppTheme.background)
    }
}

private struct LessonListCard: View {
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

private enum LessonPresentation {
    static func title(for lesson: Lesson) -> String {
        switch lesson.id {
        case 0: "Active Recalling"
        case 2: "Association"
        default: lesson.short
        }
    }

    static func symbol(for lesson: Lesson) -> String {
        switch lesson.id {
        case 0: "rectangle.portrait.and.arrow.forward"
        case 1: "line.3.horizontal"
        case 2: "circle.hexagongrid"
        default: "photo"
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
        case 0: .black
        case 1: Color(hex: "457d2e")
        case 2: Color(hex: "003cc5")
        case 3: .red
        default: Color(hex: "ce8d00")
        }
    }
}

struct LessonIcon: View {
    let lesson: Lesson
    var size: CGFloat = 90

    var body: some View {
        Group {
            if lesson.id == 0 {
                RecallIcon()
                    .stroke(.black, style: StrokeStyle(lineWidth: size * 0.022, lineCap: .round, lineJoin: .round))
                    .frame(width: size * 0.42, height: size * 0.42)
            } else {
                Image(systemName: LessonPresentation.symbol(for: lesson))
                    .font(.system(size: size * 0.42, weight: .light))
                    .foregroundStyle(LessonPresentation.foreground(for: lesson))
            }
        }
        .frame(width: size, height: size)
        .background(LessonPresentation.background(for: lesson), in: RoundedRectangle(cornerRadius: 9))
        .accessibilityHidden(true)
    }
}

// The open card and question mark share the same proportions at both icon sizes.
private struct RecallIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
        }
        path.move(to: point(0.48, 0.9))
        path.addLine(to: point(0.2, 0.9))
        path.addQuadCurve(to: point(0.08, 0.78), control: point(0.08, 0.9))
        path.addLine(to: point(0.08, 0.2))
        path.addQuadCurve(to: point(0.2, 0.08), control: point(0.08, 0.08))
        path.addLine(to: point(0.68, 0.08))
        path.addQuadCurve(to: point(0.8, 0.2), control: point(0.8, 0.08))
        path.addLine(to: point(0.8, 0.38))
        path.move(to: point(0.58, 0.62))
        path.addCurve(to: point(0.71, 0.76), control1: point(0.58, 0.41), control2: point(0.99, 0.51))
        path.move(to: point(0.7, 0.9))
        path.addLine(to: point(0.7, 0.905))
        return path
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

private struct LessonSubjectMenu: View {
    @Environment(ProgressStore.self) private var store

    var body: some View {
        @Bindable var store = store
        Picker("Example subject", selection: $store.progress.subject) {
            ForEach(Subject.allCases) { Text($0.title).tag($0) }
        }
        .font(.subheadline)
        .pickerStyle(.menu)
        .tint(AppTheme.ink)
        .onChange(of: store.progress.subject) { store.save() }
    }
}
