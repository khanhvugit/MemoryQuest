import SwiftUI
import Observation

enum AppTab: String, CaseIterable, Identifiable {
    case home = "Home", lessons = "Lessons", challenges = "Challenges", progress = "Progress"
    var id: String { rawValue }
    var symbol: String { switch self { case .home: "house"; case .lessons: "book"; case .challenges: "star"; case .progress: "chart.bar.xaxis" } }
}
enum Route: Hashable {
    case lesson(Int), reader(Int), lessonComplete(Int), challenge(Int), session(Int, Subject, Difficulty), result(UUID), reward(UUID, Bool), city(Bool), building(Int, preview: Bool = false), history(Int), settings
}
@Observable final class AppState {
    var tab = AppTab.home
    var path: [Route] = []
    var selectedTab: AppTab {
        guard let route = path.last else { return tab }
        switch route {
        case .lesson, .reader, .lessonComplete: return .lessons
        case .challenge, .session, .result, .reward: return .challenges
        case .city, .building, .settings: return .home
        case .history: return .progress
        }
    }

    func navigate(_ tab: AppTab) { self.tab = tab; path = [] }

    func showResult(_ attempt: ChallengeAttempt) {
        let session = Route.session(attempt.challengeID, attempt.subject, attempt.difficulty)
        guard path.last == session else { return }
        path[path.count - 1] = .result(attempt.id)
    }
}
