import SwiftUI
import Observation

enum AppTab: String, CaseIterable, Identifiable {
    case home = "Home", lessons = "Lessons", challenges = "Challenges", progress = "Progress"
    var id: String { rawValue }
    var symbol: String { switch self { case .home: "house"; case .lessons: "book"; case .challenges: "medal"; case .progress: "chart.bar.xaxis" } }
}
enum Route: Hashable {
    case lesson(Int), reader(Int), lessonComplete(Int), challenge(Int), session(Int, Subject, Difficulty), result(UUID), reward(UUID, Bool), city(Bool), cityAddition(Int), building(Int), history(Int), settings
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case day
    case night
    case system

    var id: String { rawValue }

    var title: String {
        switch self {
        case .night: "Night"
        case .day: "Day"
        case .system: "System"
        }
    }

    var symbol: String {
        switch self {
        case .night: "moon.stars.fill"
        case .day: "sun.max.fill"
        case .system: "circle.lefthalf.filled"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .night: .dark
        case .day: .light
        case .system: nil
        }
    }
}

@Observable final class AppState {
    var tab = AppTab.home
    var path: [Route] = []
    var appearance: AppAppearance {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: "appAppearance") }
    }

    init() {
        appearance = AppAppearance(rawValue: UserDefaults.standard.string(forKey: "appAppearance") ?? "") ?? .system
    }

    func navigate(_ tab: AppTab) { self.tab = tab; path = [] }
}
