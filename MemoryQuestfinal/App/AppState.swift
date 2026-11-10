import SwiftUI
import Observation

enum AppTab: String, CaseIterable, Identifiable {
    case home = "Home", lessons = "Lessons", challenges = "Challenges", progress = "Progress"
    var id: String { rawValue }
    var symbol: String { switch self { case .home: "house"; case .lessons: "book"; case .challenges: "medal"; case .progress: "chart.bar.xaxis" } }
}
enum Route: Hashable {
    case lesson(Int), reader(Int), lessonComplete(Int), challenge(Int), session(Int, Subject, Difficulty), result(UUID), reward(UUID, Bool), city(Bool), building(Int), history(Int), settings
}
@Observable final class AppState {
    var tab = AppTab.home
    var path: [Route] = []
    func navigate(_ tab: AppTab) { self.tab = tab; path = [] }
}
