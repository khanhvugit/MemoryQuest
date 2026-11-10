import Foundation
import Testing
@testable import MemoryQuestfinal

@MainActor struct MemoryQuestTests {
    func store() -> ProgressStore {
        ProgressStore(url: FileManager.default.temporaryDirectory.appending(path: "MemoryQuest-\(UUID().uuidString)/progress.json"))
    }

    @Test func normalisationAndAliases() {
        let content = ContentRepository.computerScience
        #expect(Answer.correct("  BOOL  ", concept: content.terms[7]))
        #expect(Answer.correct("DATA   BASE", concept: content.terms[8]))
        #expect(!Answer.correct("", concept: content.terms[0]))
        #expect(Answer.correct("mRNA", concept: ContentRepository.biology.terms[8]))
    }

    @Test func lessonCheckInvalidatesWhenAnswerChanges() {
        let model = LessonViewModel(step: 3)
        model.answer = "Stack"
        model.check(id: 0, subject: .computerScience)
        #expect(model.passed)
        model.answer = "Queue"
        #expect(!model.passed)
        model.choice = 1
        model.check(id: 3, subject: .computerScience)
        #expect(model.passed)
        model.choice = 0
        #expect(!model.passed)
    }

    @Test func representativeScoringAndCompletionReward() {
        let persistence = store()
        let session = ChallengeSessionViewModel(id: 0, subject: .computerScience, difficulty: .medium, history: [])
        session.beginRecall()
        while !session.finished {
            session.answer = session.index == 0 ? session.deck[session.index].concept.term : "wrong"
            session.check()
            session.check() // A repeated check must not add another result.
            session.advance()
        }
        let attempt = session.finish(store: persistence)
        #expect(attempt?.score == 10)
        #expect(attempt?.results.count == 10)
        #expect(persistence.progress.buildings == [0])
        _ = session.finish(store: persistence)
        #expect(persistence.progress.attempts.count == 1)
    }

    @Test func subjectHistoryAndBuildingsStaySeparate() {
        let persistence = store()
        let result = QuestionResult(conceptID: "stack", term: "Stack", answer: "Queue", expected: "Stack", explanation: "", correct: false)
        let first = ChallengeAttempt(id: UUID(), challengeID: 0, subject: .computerScience, difficulty: .easy, date: Date().addingTimeInterval(-172800), duration: 12, results: [result], selfRated: false)
        #expect(persistence.record(first))
        var biology = first
        biology.id = UUID()
        biology.subject = .biology
        #expect(!persistence.record(biology))
        #expect(persistence.progress.buildings.count == 1)
        #expect(persistence.attempts(0, subject: .biology).count == 1)
        let review = ChallengeSessionViewModel(id: 6, subject: .biology, difficulty: .medium, history: [first])
        #expect(review.deck.allSatisfy { $0.sample })
        #expect(review.deck.allSatisfy { $0.concept.term != "Stack" })
    }

    @Test func savesAndRestoresProgress() throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "MemoryQuest-\(UUID().uuidString)/progress.json")
        let first = ProgressStore(url: url)
        first.progress.name = "Wilson"
        first.progress.welcomed = true
        first.progress.completedLessons = [0, 3]
        first.progress.lessonSteps[2] = 3
        first.progress.subject = .biology
        first.save()
        let restored = ProgressStore(url: url)
        #expect(restored.progress.name == "Wilson")
        #expect(restored.progress.completedLessons == [0, 3])
        #expect(restored.progress.lessonSteps[2] == 3)
        #expect(restored.progress.subject == .biology)
        try Data("invalid JSON".utf8).write(to: url)
        let recovered = ProgressStore(url: url)
        #expect(!recovered.progress.welcomed)
        #expect(recovered.storageMessage != nil)
    }

    @Test func sequenceScoringAndBiologyChecklist() {
        let sequence = ChallengeSessionViewModel(id: 3, subject: .biology, difficulty: .hard, history: [])
        sequence.beginRecall()
        sequence.order = [1, 0]
        sequence.checkSequence()
        #expect(sequence.results.count == 1)
        #expect(sequence.results.filter(\.correct).count == 0)
        let robot = ChallengeSessionViewModel(id: 8, subject: .biology, difficulty: .medium, history: [])
        robot.index = 1
        robot.answer = "A ribosome reads mRNA and joins amino acids to build a protein."
        robot.check()
        #expect(robot.results.count == 3)
        #expect(robot.results.allSatisfy(\.correct))
    }

    @Test func rescueRetriesAndDelayedRecall() {
        let rescue = ChallengeSessionViewModel(id: 7, subject: .biology, difficulty: .medium, history: [])
        let count = rescue.deck.count
        for _ in 0..<count {
            rescue.answer = "wrong"
            rescue.check()
            rescue.advance()
        }
        #expect(rescue.retried)
        #expect(!rescue.finished)
        while !rescue.finished {
            rescue.answer = rescue.deck[rescue.index].concept.term
            rescue.check()
            rescue.advance()
        }
        #expect(rescue.rescued.count == count)
        #expect(rescue.results.count == count * 2)
        #expect(!rescue.results.contains(where: \.delayed))
        let result = QuestionResult(conceptID: "stack", term: "Stack", answer: "", expected: "Stack", explanation: "", correct: false)
        let prior = ChallengeAttempt(id: UUID(), challengeID: 0, subject: .computerScience, difficulty: .medium, date: Date().addingTimeInterval(-172800), duration: 1, results: [result], selfRated: false)
        let review = ChallengeSessionViewModel(id: 6, subject: .computerScience, difficulty: .hard, history: [prior])
        if let index = review.deck.firstIndex(where: { $0.concept.term == "Stack" }) {
            review.index = index
            review.answer = "stack"
            review.check()
            #expect(review.results.last?.delayed == true)
            #expect(review.results.last?.sample == false)
        } else { Issue.record("An earlier missed Stack should be prioritised.") }
    }
    @Test func everyChallengeCompletesAtSelectedQuestionCount() {
        for subject in Subject.allCases {
            for difficulty in Difficulty.allCases {
                for id in 0..<10 {
                    let session = ChallengeSessionViewModel(id: id, subject: subject, difficulty: difficulty, history: [])
                    #expect(session.total == difficulty.questionCount)
                    if id == 2 { session.groupRecall() } else { session.beginRecall() }
                    for question in 0..<difficulty.questionCount {
                        #expect(!session.finished)
                        #expect(session.index == question)
                        switch id {
                        case 1:
                            session.flipped = true
                            session.selfRate(true)
                        case 2:
                            session.answer = session.content.categories[session.groupedTerms[question].category]
                            session.check()
                            session.advance()
                        case 3:
                            session.order = Array(session.currentSequence.indices)
                            session.checkSequence()
                            session.advance()
                        case 4:
                            session.answer = session.storyTerms[question]
                            session.check()
                            session.advance()
                        case 5:
                            session.answer = session.links[question].term
                            session.check()
                            session.advance()
                        case 8:
                            session.answer = session.content.robots[question].example
                            session.check()
                            session.advance()
                        case 9:
                            session.choice = session.content.detectives[question].a
                            session.check()
                            session.advance()
                        default:
                            session.answer = session.deck[question].concept.term
                            session.check()
                            session.advance()
                        }
                    }
                    #expect(session.finished)
                    #expect(session.results.allSatisfy(\.correct))
                    if id != 8 { #expect(session.results.count == difficulty.questionCount) }
                }
            }
        }
    }

    @Test func expandedBanksContainDistinctQuestionsAndValidAnswers() {
        for subject in Subject.allCases {
            let content = ContentRepository.content(subject)
            #expect(Set(content.terms.map(\.id)).count >= 12)
            #expect(Set(content.links.map(\.term)).count >= 12)
            #expect(Set(content.detectives.map(\.q)).count >= 12)
            #expect(Set(content.robots.map(\.q)).count >= 12)
            for question in content.detectives {
                #expect(question.opts.indices.contains(question.a))
                #expect(Set(question.opts).count == question.opts.count)
            }
            for question in content.robots {
                #expect(question.rules.allSatisfy { $0.matches(question.example) })
            }
            for difficulty in Difficulty.allCases {
                let session = ChallengeSessionViewModel(id: 5, subject: subject, difficulty: difficulty, history: [])
                for index in session.links.indices { session.groups[index] = index }
                session.checkLinks()
                #expect(session.feedbackCorrect)
                #expect(session.results.count == difficulty.questionCount)
                let grouping = ChallengeSessionViewModel(id: 2, subject: subject, difficulty: difficulty, history: [])
                for index in grouping.groupedTerms.indices { grouping.groups[index] = grouping.groupedTerms[index].category }
                grouping.checkGroups()
                #expect(grouping.feedbackCorrect)
                #expect(grouping.results.isEmpty)
            }
        }
    }

}
