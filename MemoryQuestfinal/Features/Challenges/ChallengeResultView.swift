import SwiftUI

struct ChallengeResultView: View {
    let attemptID: UUID
    @Environment(ProgressStore.self) private var store
    @Environment(AppState.self) private var app
    @State private var review = false

    var body: some View {
        if let attempt = store.progress.attempts.first(where: { $0.id == attemptID }) {
            let isNew = store.progress.attempts.first(where: { $0.challengeID == attempt.challengeID && $0.passed })?.id == attemptID
            CelebrationPage {
                VStack(spacing: 20) {
                    if attempt.passed {
                        CompletionTrophy()
                            .frame(width: 200, height: 190)
                    } else {
                        Image(systemName: "arrow.clockwise.circle")
                            .font(.system(size: 100))
                            .foregroundStyle(AppTheme.muted)
                            .frame(width: 200, height: 190)
                    }
                    Text(attempt.passed ? "Challenge Complete!" : "Keep practising")

                        .font(.largeTitle.bold())
                        .tracking(-1)
                        .multilineTextAlignment(.center)
                    CompletionMetrics(
                        title: attempt.selfRated ? "Self-reported recall" : attempt.challengeID == 8 ? "Checklist coverage" : "Accuracy",
                        score: attempt.score,
                        duration: attempt.duration
                    )
                    VStack(spacing: 16) {
                        if attempt.passed {
                            CelebrationButton(title: isNew ? "Unlock new building" : "View building") {
                                app.path.append(.reward(attemptID, isNew))
                            }
                        } else {
                            CelebrationButton(title: "Try again") {
                                app.path = Array(app.path.dropLast()) + [.session(attempt.challengeID, attempt.subject, attempt.difficulty)]
                            }
                            CelebrationButton(title: "Back to challenges", secondary: true) {
                                app.navigate(.challenges)
                            }
                        }
                        CelebrationButton(title: review ? "Hide answer review" : "Review answers", secondary: true) {
                            review.toggle()
                        }
                    }
                    if review {
                        AttemptAnswersView(results: attempt.results)
                    }
                }
            }
        }
    }
}

/// Keeps the celebration centered with room to scroll on smaller displays.
struct CelebrationPage<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                content
                    .frame(maxWidth: 440)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                    .padding(.top, max(32, min(120, geometry.size.height * 0.16)))
                    .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .background(AppTheme.background)
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct CelebrationButton: View {
    let title: String
    var secondary = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body.weight(.semibold))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 56)
                .padding(.horizontal, 12)
                .foregroundStyle(secondary ? AppTheme.muted : .white)
                .background(secondary ? Color("CardBackground") : AppTheme.coral,
                            in: RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(secondary ? AppTheme.line : .clear)
                }
        }
        .buttonStyle(.plain)
    }
}

private struct CompletionMetrics: View {
    let title: String
    let score: Int
    let duration: Int
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 16) {
                    CompletionMetric(title: title, value: "\(score)%")
                    Divider()
                    CompletionMetric(title: "Time", value: "\(duration) sec")
                }
            } else {
                HStack(spacing: 0) {
                    CompletionMetric(title: title, value: "\(score)%")
                    Rectangle().fill(AppTheme.muted).frame(width: 1, height: 76)
                    CompletionMetric(title: "Time", value: "\(duration) sec")
                }
            }
        }
        .padding(.vertical, 18)
        .background(Color("CardBackground"), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct CompletionMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 10) {
            Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.muted)
            Text(value).font(.largeTitle.bold()).monospacedDigit()
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        .accessibilityElement(children: .combine)
    }
}

private struct CompletionTrophy: View {
    private let gold = LinearGradient(
        colors: [Color(hex: "FFD331"), Color(hex: "FFEB54"), Color(hex: "FFCA2D")],
        startPoint: .leading, endPoint: .trailing
    )

    var body: some View {
        ZStack {
            HStack {
                RoundedRectangle(cornerRadius: 30).strokeBorder(gold, lineWidth: 16)
                Spacer().frame(width: 60)
                RoundedRectangle(cornerRadius: 30).strokeBorder(gold, lineWidth: 16)
            }
            .frame(width: 194, height: 86)
            .offset(y: -21)
            Rectangle().fill(gold).frame(width: 22, height: 42).offset(y: 68)
            UnevenRoundedRectangle(bottomLeadingRadius: 60, bottomTrailingRadius: 60)
                .fill(gold)
                .frame(width: 124, height: 132)
                .offset(y: -23)
            Capsule().fill(gold).frame(width: 140, height: 20).offset(y: -85)
            Image(systemName: "star.fill")
                .font(.system(size: 50))
                .foregroundStyle(Color(hex: "FFF3AF"))
                .offset(y: -27)
            Rectangle().fill(gold).frame(width: 54, height: 13).offset(y: 88)
        }
        .accessibilityHidden(true)
    }
}

struct MetricRow: View {
    let title, value: String
    var showsDivider = true

    var body: some View {
        HStack(alignment: .top) {
            Text(title).foregroundStyle(AppTheme.muted)
            Spacer()
            Text(value).fontWeight(.semibold).multilineTextAlignment(.trailing)
        }
        if showsDivider {
            Divider()
        }
    }
}
struct AttemptAnswersView: View {
    let results: [QuestionResult]
    var body: some View {
        ForEach(results) { result in
            QuestCard {
                Label(result.term,systemImage:result.correct ? "checkmark.circle" : "arrow.clockwise").font(.headline).foregroundStyle(result.correct ? Color.green : Color.orange)
                Text("Your response: \(result.answer)").font(.subheadline).foregroundStyle(AppTheme.muted)
                Text("Correct idea: \(result.expected)").font(.subheadline)
                if !result.explanation.isEmpty { Text(result.explanation).font(.subheadline).foregroundStyle(AppTheme.muted) }
                if result.sample { Text("Sample history prompt").font(.caption) }
            }
        }
    }
}

#if DEBUG
#Preview("ChallengeResultView") {
    PreviewScreen(results: true) { ChallengeResultView(attemptID: PreviewData.attempt.id) }
}

#Preview("MetricRow") {
    PreviewScreen() { MetricRow(title: "Accuracy", value: "50%") }
}

#Preview("AttemptAnswersView") {
    PreviewScreen() { QuestPage { AttemptAnswersView(results: PreviewData.attempt.results) } }
}
#endif
