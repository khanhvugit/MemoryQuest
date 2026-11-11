import Foundation
import Observation

@MainActor @Observable final class ProgressStore {
    var progress: LearningProgress
    var storageMessage: String?
    private let url: URL
    init(url: URL? = nil) {
        self.url = url ?? URL.applicationSupportDirectory.appending(path: "MemoryQuest/progress.json")
        do {
            let data = try Data(contentsOf: self.url)
            progress = try JSONDecoder().decode(LearningProgress.self, from: data)
        } catch {
            progress = LearningProgress()
            if FileManager.default.fileExists(atPath: self.url.path) {
                storageMessage = "Saved progress could not be read. A recovery copy has been kept."
                try? FileManager.default.copyItem(at: self.url, to: self.url.appendingPathExtension("recovery-\(UUID().uuidString)"))
            }
        }
    }
    func save() {
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(progress).write(to: url, options: .atomic)
        } catch { storageMessage = "Your latest progress could not be saved. Please try again." }
    }
    func attempts(_ challenge: Int, subject: Subject? = nil) -> [ChallengeAttempt] {
        progress.attempts.filter { $0.challengeID == challenge && (subject == nil || $0.subject == subject) }
    }
    @discardableResult func record(_ attempt: ChallengeAttempt) -> Bool {
        guard !progress.attempts.contains(where: { $0.id == attempt.id }) else { return false }
        let isNew = attempt.passed && !progress.buildings.contains(attempt.challengeID)
        progress.attempts.append(attempt)
        if [6, 7].contains(attempt.challengeID) {
            for result in attempt.results {
                progress.reviews.removeAll { $0.subject == attempt.subject && $0.conceptID == result.conceptID }
                progress.reviews.append(ReviewRecord(subject: attempt.subject, conceptID: result.conceptID, term: result.term, date: attempt.date, due: attempt.date.addingTimeInterval(result.correct ? 172800 : 86400), correct: result.correct))
            }
        }
        save()
        return isNew
    }
    func reset() { progress = LearningProgress(); save() }
}
