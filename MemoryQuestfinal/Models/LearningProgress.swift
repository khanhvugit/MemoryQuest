import Foundation

struct QuestionResult: Codable, Identifiable {
    var id = UUID()
    var conceptID: String
    var term, answer, expected, explanation: String
    var correct: Bool
    var delayed = false
    var sample = false
}
struct ChallengeAttempt: Codable, Identifiable {
    var id: UUID
    var challengeID: Int
    var subject: Subject
    var difficulty: Difficulty
    var date: Date
    var duration: Int
    var results: [QuestionResult]
    var selfRated: Bool
    var passed: Bool { !results.isEmpty && results.filter(\.correct).count * 100 >= results.count * 90 }
    var score: Int { results.isEmpty ? 0 : Int((Double(results.filter(\.correct).count) / Double(results.count) * 100).rounded()) }
}
struct ReviewRecord: Codable, Identifiable {
    var id: String { subject.rawValue + ":" + conceptID }
    var subject: Subject
    var conceptID, term: String
    var date, due: Date
    var correct: Bool
}
struct LearningProgress: Codable {
    var version = 1
    var name = "Alex"
    var welcomed = false
    var subject = Subject.computerScience
    var completedLessons: Set<Int> = []
    var lessonSteps: [Int: Int] = [:]
    var attempts: [ChallengeAttempt] = []
    var reviews: [ReviewRecord] = []
    var buildings: Set<Int> { Set(attempts.filter(\.passed).map(\.challengeID)) }
    var completion: Int { Int((Double(completedLessons.count + buildings.count) / 15 * 100).rounded()) }
}
