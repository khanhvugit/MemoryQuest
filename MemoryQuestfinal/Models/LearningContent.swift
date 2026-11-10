import Foundation

enum Subject: String, Codable, CaseIterable, Identifiable {
    case computerScience, biology
    var id: String { rawValue }
    var title: String { self == .biology ? "Biology" : "Computer Science" }
}
enum Difficulty: String, Codable, CaseIterable, Identifiable {
    case easy = "Easy", medium = "Medium", hard = "Hard"
    var id: String { rawValue }
    var questionCount: Int {
        switch self {
        case .easy: 5
        case .medium: 10
        case .hard: 12
        }
    }
}
struct Lesson: Codable, Identifiable {
    let id: Int
    let title, short, desc, symbol, soft, deep, light, dark, routine, summary: String
    let pages: [LessonPage]
}
struct LessonPage: Codable { var title, body: String; var blocks: [LessonBlock]? }
struct LessonBlock: Codable, Identifiable { let id, kind, text: String }
struct Challenge: Codable, Identifiable {
    let id, l: Int
    let title, building, desc, instructions, mins, kind: String
}
struct Concept: Codable, Identifiable {
    var id: String { Answer.normalise(term) }
    let term, def, hint: String
    let aliases: [String]
}
struct Analogy: Codable { let term, cue, why: String }
struct Scenario: Codable { let q: String; let opts: [String]; let a: Int; let why, term: String }
struct Explanation: Codable { let q, example: String; let rules: [IdeaRule] }
struct IdeaRule: Codable {
    let name: String
    let patterns: [String]
    let all: Bool
    func matches(_ answer: String) -> Bool {
        let checks = patterns.map { answer.range(of: $0, options: [.regularExpression, .caseInsensitive]) != nil }
        return all ? checks.allSatisfy { $0 } : checks.contains(true)
    }
}
struct SubjectContent: Codable {
    let terms: [Concept]
    let categories: [String]
    let groups: [[String]]
    let links: [Analogy]
    let sequence, chunks, storyTerms: [String]
    let story: String
    let detectives: [Scenario]
    let robots: [Explanation]
}
enum Answer {
    static func normalise(_ value: String) -> String {
        value.lowercased().replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression).replacingOccurrences(of: "[^a-z0-9 ]", with: "", options: .regularExpression)
            .split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
    static func correct(_ answer: String, concept: Concept) -> Bool {
        !normalise(answer).isEmpty && concept.aliases.contains { normalise($0) == normalise(answer) }
    }
    static func contains(_ answer: String, term: String) -> Bool {
        normalise(answer).range(of: "\\b" + NSRegularExpression.escapedPattern(for: normalise(term)) + "\\b", options: .regularExpression) != nil
    }
}
