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
    var retry: [ReviewConcept] = []
    var retried = false
    var rescued: Set<String> = []
    var finished = false
    private var savedAttempt: ChallengeAttempt?
    init(id: Int, subject: Subject, difficulty: Difficulty, history: [ChallengeAttempt]) {
        self.id=id; self.subject=subject; self.difficulty=difficulty
        content=ContentRepository.content(subject)
        let terms=ContentRepository.content(subject).terms
        deck=Array(terms.prefix(difficulty == .hard ? 10 : 8)).map { ReviewConcept(concept:$0,lastSeen:nil,missed:false) }
        if [1,6,7,8,9].contains(id) { stage="play" }
        if [6,7].contains(id) {
            let relevant=history.filter { $0.subject == subject && !$0.selfRated }
            let ranked=terms.enumerated().map { i,t -> ReviewConcept in
                let prior=relevant.flatMap { attempt in attempt.results.filter { $0.conceptID == t.id }.map { ($0,attempt.date) } }.last
                return ReviewConcept(concept:t,lastSeen:prior?.1,missed:prior.map { !$0.0.correct } ?? [3,4,2,1].contains(i))
            }.sorted { a, b in
                // Genuine learning history takes precedence over sample filler.
                if a.sample != b.sample { return !a.sample }
                if a.missed != b.missed { return a.missed }
                if a.lastSeen != b.lastSeen { return (a.lastSeen ?? .distantPast) < (b.lastSeen ?? .distantPast) }
                return a.concept.id < b.concept.id
            }
            deck=Array(ranked.prefix(id == 7 ? 4 : (difficulty == .hard ? 6 : 4)))
        }
    }
    var total: Int { stage == "groupRecall" ? 3 : id == 5 ? content.links.count : id == 8 ? content.robots.count : id == 9 ? content.detectives.count : deck.count }
    var canCheck: Bool {
        guard !finished, stage != "study", index >= 0, index < total else { return false }
        return id == 9 ? content.detectives[index].opts.indices.contains(choice) : !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    func record(_ term: String, answer: String, expected: String, correct: Bool, explanation: String = "", delayed: Bool = false, sample: Bool = false) {
        results.append(QuestionResult(conceptID:Answer.normalise(term),term:term,answer:answer,expected:expected,explanation:explanation,correct:correct,delayed:delayed,sample:sample))
    }
    func beginRecall() { guard stage == "study", !finished else { return }; stage="play"; index=0; feedback=nil; validation=nil; answer=""; groups=[:] }
    func checkGroups() {
        guard stage == "study", !finished, feedback == nil else { return }
        guard groups.count == 9, groups.values.allSatisfy({ (0..<3).contains($0) }) else { validation="Choose a category for every term, then check your groups."; return }
        var count=0
        for i in 0..<9 {
            let term=content.groups[i/3][i%3], selected=groups[i,default:0], correct=selected == i/3
            if correct { count += 1 }
            record(term,answer:content.categories[selected],expected:content.categories[i/3],correct:correct,explanation:"\(term) belongs to \(content.categories[i/3]).")
        }
        feedbackCorrect=count == 9
        feedback="\(count)/9 grouped correctly.\n\n" + (0..<3).map { content.categories[$0]+": "+content.groups[$0].joined(separator:", ") }.joined(separator:"\n\n") + "\n\nUse the group labels as cues. Next, the list will be hidden."
        validation=nil
    }
    func groupRecall() { guard stage == "study", feedback != nil, !finished else { return }; stage="groupRecall"; feedback=nil; answer=""; index=0; groups=[:] }
    func checkLinks() {
        guard stage == "study", !finished, feedback == nil else { return }
        guard groups.count == content.links.count, groups.values.allSatisfy({ (0..<content.links.count).contains($0) }) else { validation="Select an analogy for every concept."; return }
        var count=0
        for i in content.links.indices {
            let link=content.links[i], chosen=groups[i,default:0], correct=chosen == i
            if correct { count += 1 }
            record(link.term,answer:content.links[chosen].cue,expected:link.cue,correct:correct,explanation:link.why)
        }
        feedbackCorrect=count == content.links.count
        feedback="\(count)/4 connections matched.\n\n"+content.links.map { "\($0.term) → \($0.cue)\n\($0.why)" }.joined(separator:"\n\n")
        validation=nil
    }
    func hideStory() {
        guard stage == "study", !finished else { return }
        let missing=content.storyTerms.filter { !Answer.contains(story,term:$0) }
        guard story.trimmingCharacters(in:.whitespacesAndNewlines).count >= 30, missing.isEmpty else {
            validation="Build a short story using all four terms. Still needed: \(missing.joined(separator:", "))."; return
        }
        beginRecall()
    }
    func checkSequence() {
        guard !finished, stage == "play", order.count == 6, Set(order).count == 6, order.allSatisfy({ content.sequence.indices.contains($0) }), feedback == nil else { return }
        for (position,selection) in order.enumerated() { record("Operation \(position+1)",answer:content.sequence[selection],expected:content.sequence[position],correct:position == selection,explanation:content.chunks.joined(separator:" → ")) }
        feedbackCorrect=order == Array(0..<6)
        feedback="\(zip(order,0..<6).filter { $0 == $1 }.count)/6 operations in position.\n\n"+content.sequence.joined(separator:" → ")+"\n\n"+content.chunks.joined(separator:" → ")
    }
    func selfRate(_ correct: Bool) {
        guard id == 1, !finished, flipped, deck.indices.contains(index) else { return }
        let concept=deck[index].concept
        record(concept.term,answer:correct ? "Recalled (self-rated)" : "Needed review (self-rated)",expected:concept.def,correct:correct)
        advance()
    }
    func check() {
        guard feedback == nil, canCheck else { return }
        validation=nil
        if stage == "groupRecall" {
            let terms=content.groups[index], count=terms.filter { Answer.contains(answer,term:$0) }.count
            feedbackCorrect=count >= 2
            record(content.categories[index],answer:answer,expected:terms.joined(separator:", "),correct:feedbackCorrect,explanation:"Name at least two members of this category.")
            feedback="\(content.categories[index]): \(terms.joined(separator:", ")). You needed at least two."
        } else if id == 4 {
            for term in content.storyTerms { record(term,answer:answer,expected:term,correct:Answer.contains(answer,term:term),explanation:content.terms.first { $0.term == term }?.def ?? "") }
            feedbackCorrect=content.storyTerms.allSatisfy { Answer.contains(answer,term:$0) }
            feedback="The original concepts were \(content.storyTerms.joined(separator:", ")).\n\nRetrieving keywords does not establish conceptual understanding. Compare their roles with the definitions."
        } else if id == 8 {
            let question=content.robots[index]
            let checks=question.rules.map { ($0.name,$0.matches(answer)) }
            for check in checks { record(check.0,answer:answer,expected:check.0,correct:check.1,explanation:question.example) }
            feedbackCorrect=checks.allSatisfy { $0.1 }
            feedback=checks.map { "\($0.1 ? "✓ Included" : "↻ Not detected"): \($0.0)" }.joined(separator:"\n")+"\n\nExample: \(question.example)\n\nA correct explanation may use wording the checklist does not recognise. Use this feedback as a prompt to check your answer."
        } else if id == 9 {
            let question=content.detectives[index]
            feedbackCorrect=choice == question.a
            record(question.term,answer:question.opts[choice],expected:question.opts[question.a],correct:feedbackCorrect,explanation:question.why)
            feedback=question.why
        } else if id == 5 {
            let link=content.links[index]
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
        guard !finished, stage != "study", feedback != nil || (id == 1 && flipped) else { return }
        if [3,4].contains(id) { finished=true; return }
        index += 1; feedback=nil; answer=""; choice = -1; hint=false; flipped=false
        if index >= total {
            if id == 7 && !retried && !retry.isEmpty { deck=retry; retry=[]; retried=true; index=0 }
            else { finished=true }
        }
    }
    func finish(store: ProgressStore) -> ChallengeAttempt? {
        guard finished else { return nil }
        if let savedAttempt { return savedAttempt }
        let attempt=ChallengeAttempt(id:attemptID,challengeID:id,subject:subject,difficulty:difficulty,date:Date(),duration:max(1,Int(Date().timeIntervalSince(started).rounded())),results:results,selfRated:id == 1)
        store.record(attempt); savedAttempt=attempt
        return attempt
    }
}
