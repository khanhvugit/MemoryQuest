import Foundation
import Observation

struct ReviewConcept {
    let concept: Concept
    let lastSeen: Date?
    let missed: Bool
    var sample: Bool { lastSeen == nil }
}
@Observable final class ChallengeSessionViewModel {
    let id: Int
    let subject: Subject
    let difficulty: Difficulty
    let content: SubjectContent
    let attemptID = UUID()
    let started = Date()
    var stage = "study"
    var index = 0
    var answer = ""
    var choice = -1
    var groups: [Int: Int] = [:]
    var order: [Int] = []
    var story = ""
    var flipped = false
    var hint = false
    var feedback: String?
    var feedbackCorrect = false
    var validation: String?
    var results: [QuestionResult] = []
    var deck: [ReviewConcept]
    let groupedTerms: [(term: String, category: Int)]
    let storyTerms: [String]
    let sequenceQuestions: [[String]]
    let links: [Analogy]
    let robots: [Explanation]
    let detectives: [Scenario]
    var retry: [ReviewConcept] = []
    var retried = false
    var rescued: Set<String> = []
    var finished = false
    private var savedAttempt: ChallengeAttempt?
    init(id: Int, subject: Subject, difficulty: Difficulty, history: [ChallengeAttempt]) {
        self.id=id; self.subject=subject; self.difficulty=difficulty
        let sessionContent = ContentRepository.content(subject)
        content = sessionContent
        let terms = sessionContent.terms
        deck=Array(terms.prefix(difficulty.questionCount))
            .shuffled()
            .map { ReviewConcept(concept:$0,lastSeen:nil,missed:false) }
        groupedTerms = Array((0..<4).flatMap { position in
            sessionContent.groups.indices.map { category in
                (term: sessionContent.groups[category][position], category: category)
            }
        }.prefix(difficulty.questionCount)).shuffled()
        storyTerms = Array(sessionContent.storyTerms.prefix(difficulty.questionCount)).shuffled()
        sequenceQuestions = Array((2...4).flatMap { length in
            (0...(sessionContent.sequence.count - length)).map { start in
                Array(sessionContent.sequence[start..<(start + length)])
            }
        }.prefix(difficulty.questionCount)).shuffled()
        links = Array(sessionContent.links.prefix(difficulty.questionCount)).shuffled()
        robots = Array(sessionContent.robots.prefix(difficulty.questionCount)).shuffled()
        detectives = Array(sessionContent.detectives.prefix(difficulty.questionCount)).shuffled()
        if [1,6,7,8,9].contains(id) { stage="play" }
        if [6,7].contains(id) {
            let relevant=history.filter { $0.subject == subject && !$0.selfRated }
            let ranked=terms.enumerated().map { i,t -> ReviewConcept in
                let prior=relevant.flatMap { attempt in attempt.results.filter { $0.conceptID == t.id }.map { ($0,attempt.date) } }.last
                return ReviewConcept(concept:t,lastSeen:prior?.1,missed:prior.map { !$0.0.correct } ?? [3,4,2,1].contains(i))
            }.sorted { a,b in a.missed != b.missed ? a.missed : (a.lastSeen ?? .distantPast) < (b.lastSeen ?? .distantPast) }
            deck=Array(ranked.prefix(difficulty.questionCount)).shuffled()
        }
    }
    var total: Int { retried ? deck.count : difficulty.questionCount }
    var currentSequence: [String] { sequenceQuestions[index] }
    var canCheck: Bool { id == 9 ? choice >= 0 : !answer.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty }
    func record(_ term: String, answer: String, expected: String, correct: Bool, explanation: String = "", delayed: Bool = false, sample: Bool = false) {
        results.append(QuestionResult(conceptID:Answer.normalise(term),term:term,answer:answer,expected:expected,explanation:explanation,correct:correct,delayed:delayed,sample:sample))
    }
    func beginRecall() { stage="play"; index=0; feedback=nil; validation=nil; answer=""; groups=[:] }
    func checkGroups() {
        guard feedback == nil else { return }
        guard groups.count == groupedTerms.count,
              groups.values.allSatisfy({ content.categories.indices.contains($0) }) else {
            validation = "Choose a category for every term, then check your groups."
            return
        }
        let count = groupedTerms.indices.filter { groups[$0] == groupedTerms[$0].category }.count
        feedbackCorrect = count == groupedTerms.count
        feedback = "\(count)/\(groupedTerms.count) grouped correctly.\n\n" +
            groupedTerms.map { "\($0.term) → \(content.categories[$0.category])" }.joined(separator: "\n") +
            "\n\nNext, hide the groups and recall each category."

        validation=nil
    }
    func groupRecall() { stage="groupRecall"; feedback=nil; answer=""; index=0; groups=[:] }
    func checkLinks() {
        guard feedback == nil else { return }
        guard groups.count == links.count, groups.values.allSatisfy({ (0..<links.count).contains($0) }) else { validation="Select an analogy for every concept."; return }
        var count=0
        for i in links.indices {
            let chosen=groups[i,default:0], correct=chosen == i
            if correct { count += 1 }
        }
        feedbackCorrect=count == links.count
        feedback="\(count)/\(links.count) connections matched.\n\n"+links.map { "\($0.term) → \($0.cue)\n\($0.why)" }.joined(separator:"\n\n")
        validation=nil
    }
    func hideStory() {
        let missing=storyTerms.filter { !Answer.contains(story,term:$0) }
        guard story.trimmingCharacters(in:.whitespacesAndNewlines).count >= 30, missing.isEmpty else {
            validation="Build a short story using all \(storyTerms.count) terms. Still needed: \(missing.joined(separator:", "))."; return
        }
        beginRecall()
    }
    func checkSequence() {
        guard order.count == currentSequence.count, feedback == nil else { return }
        feedbackCorrect = order == Array(currentSequence.indices)
        record("Sequence \(index + 1)", answer: order.map { currentSequence[$0] }.joined(separator: " → "),
               expected: currentSequence.joined(separator: " → "), correct: feedbackCorrect)
        feedback = currentSequence.joined(separator: " → ")
    }

    func selfRate(_ correct: Bool) {
        guard flipped else { return }
        let concept=deck[index].concept
        record(concept.term,answer:correct ? "Recalled (self-rated)" : "Needed review (self-rated)",expected:concept.def,correct:correct)
        advance()
    }
    func check() {
        guard feedback == nil, canCheck else { return }
        validation=nil
        if stage == "groupRecall" {
            let item = groupedTerms[index]
            let category = content.categories[item.category]
            feedbackCorrect = Answer.normalise(answer) == Answer.normalise(category)
            record(item.term, answer: answer, expected: category, correct: feedbackCorrect)
            feedback = "\(item.term) belongs to \(category)."
        } else if id == 4 {
            let term = storyTerms[index]
            let concept = content.terms.first { $0.term == term }
            feedbackCorrect = concept.map { Answer.correct(answer, concept: $0) } ?? false
            record(term, answer: answer, expected: term, correct: feedbackCorrect)
            feedback = "\(term) — \(concept?.def ?? "")"
        } else if id == 8 {
            let question=robots[index]
            let checks=question.rules.map { ($0.name,$0.matches(answer)) }
            for check in checks { record(check.0,answer:answer,expected:check.0,correct:check.1,explanation:question.example) }
            feedbackCorrect=checks.allSatisfy { $0.1 }
            feedback=checks.map { "\($0.1 ? "✓ Included" : "↻ Not detected"): \($0.0)" }.joined(separator:"\n")+"\n\nExample: \(question.example)\n\nA correct explanation may use wording the checklist does not recognise. Use this feedback as a prompt to check your answer."
        } else if id == 9 {
            let question=detectives[index]
            feedbackCorrect=choice == question.a
            record(question.term,answer:question.opts[choice],expected:question.opts[question.a],correct:feedbackCorrect,explanation:question.why)
            feedback=question.why
        } else if id == 5 {
            let link=links[index]
            feedbackCorrect=Answer.normalise(answer) == Answer.normalise(link.term) || content.terms.first(where: { $0.term == link.term }).map { Answer.correct(answer,concept:$0) } == true
            record(link.term,answer:answer,expected:link.term,correct:feedbackCorrect,explanation:link.why)
            feedback="\(link.term) — \(link.why)"
        } else {
            let item=deck[index], concept=item.concept
            feedbackCorrect=Answer.correct(answer,concept:concept)
            let delayed=id == 6 && item.lastSeen.map { Date().timeIntervalSince($0) >= 86400 } == true
            record(concept.term,answer:answer,expected:concept.term,correct:feedbackCorrect,explanation:concept.def,delayed:delayed,sample:[6,7].contains(id) && item.sample)
            if id == 7 {
                if feedbackCorrect { rescued.insert(concept.id) }
                else if !retried { retry.append(item) }
            }
            feedback="\(feedbackCorrect ? "You retrieved it!" : "A useful gap to revisit")\n\n\(concept.term) — \(concept.def)"
            if id == 6 { feedback = (feedback ?? "") + "\n\nNext review: \(Date().addingTimeInterval(feedbackCorrect ? 172800 : 86400).formatted(date:.abbreviated,time:.omitted))." }
        }
    }
    func advance() {
        guard !finished else { return }
        if index + 1 >= total {
            if id == 7 && !retried && !retry.isEmpty {
                index = 0
                deck = retry
                retry = []
                retried = true
            } else {
                // Keep the last question valid while its view leaves the hierarchy.
                finished = true
                return
            }
        } else {
            index += 1
        }
        order = []
        feedback = nil
        answer = ""
        choice = -1
        hint = false
        flipped = false
    }
    func finish(store: ProgressStore) -> ChallengeAttempt? {
        guard finished else { return nil }
        if let savedAttempt { return savedAttempt }
        let attempt=ChallengeAttempt(id:attemptID,challengeID:id,subject:subject,difficulty:difficulty,date:Date(),duration:max(1,Int(Date().timeIntervalSince(started).rounded())),results:results,selfRated:id == 1)
        store.record(attempt); savedAttempt=attempt
        return attempt
    }
}
