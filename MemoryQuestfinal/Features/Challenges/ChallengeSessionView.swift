import SwiftUI

struct ChallengeSessionView: View {
    let id: Int
    let subject: Subject
    let difficulty: Difficulty
    @Environment(ProgressStore.self) private var store
    @Environment(AppState.self) private var app
    @State private var model: ChallengeSessionViewModel?
    var body: some View {
        Group {
            if let model {
                QuestPage {
                    if !model.finished {
                        if model.stage == "study" { StudyActivityView(model:model) }
                        else {
                            ProgressView(value:Double(model.index),total:Double(model.total))
                            Text(model.retried ? "Second chance · \(model.index + 1) of \(model.total)" : "Question \(model.index + 1) of \(model.total)").font(.caption).foregroundStyle(AppTheme.muted)
                            if model.stage == "groupRecall" { RetrievalActivityView(model:model) }
                            else {
                                switch id {
                                case 1: FlashcardActivityView(model:model)
                                case 3: SequenceActivityView(model:model)
                                case 8: ExplanationActivityView(model:model)
                                case 9: DetectiveActivityView(model:model)
                                default: RetrievalActivityView(model:model)
                                }
                            }
                        }
                        if let validation=model.validation { FeedbackView(text:validation,correct:false) }
                        if let feedback=model.feedback {
                            FeedbackView(text:feedback,correct:model.feedbackCorrect)
                            QuestButton(title:model.stage == "study" ? (id == 2 ? "Hide groups & recall" : "Hide links & retrieve") : (model.index + 1 == model.total ? "See results" : "Next")) {
                                if model.stage == "study" { if id == 2 { model.groupRecall() } else { model.beginRecall() } }
                                else { model.advance() }
                            }
                        }
                    }
                }.id("\(model.stage)-\(model.index)-\(model.retried)")
                    .onChange(of:model.finished) {
                        if let attempt=model.finish(store:store) { app.path.removeLast(); app.path.append(.result(attempt.id)) }
                    }
            } else { ProgressView().onAppear { model=ChallengeSessionViewModel(id:id,subject:subject,difficulty:difficulty,history:store.progress.attempts) } }
        }.navigationTitle(ContentRepository.challenges[id].title)
    }
}
struct StudyActivityView: View {
    @Bindable var model: ChallengeSessionViewModel
    var body: some View {
        VStack(alignment:.leading,spacing:20) {
            switch model.id {
            case 0:
                PageTitle(text:"Make a first connection")
                Text("Read each term and its meaning. Then hide the list and retrieve the words from memory.").font(.subheadline).foregroundStyle(AppTheme.muted)
                QuestCard { ForEach(model.deck,id:\.concept.id) { item in Text(item.concept.term).font(.headline); Text(item.concept.def).font(.subheadline) } }
                QuestButton(title:"Hide terms & begin recall") { model.beginRecall() }
            case 2: GroupingActivityView(model:model)
            case 3:
                PageTitle(text:"Three chunks. One process.")
                Text("Notice each pair’s purpose. Say the sequence once without looking.").font(.subheadline)
                ForEach(0..<3) { i in QuestCard { Text("\(i+1). \(model.content.chunks[i])").font(.headline); Text(model.content.sequence[(i*2)..<(i*2+2)].joined(separator:" → ")) } }
                QuestButton(title:"Hide sequence & reconstruct") { model.beginRecall() }
            case 4: StoryActivityView(model:model)
            case 5: LinkingActivityView(model:model)
            default: EmptyView()
            }
        }
    }
}

#if DEBUG
#Preview("ChallengeSessionView") {
    PreviewScreen() { ChallengeSessionView(id: 0, subject: .computerScience, difficulty: .easy) }
}

#Preview("StudyActivityView") {
    PreviewScreen() { QuestPage { StudyActivityView(model: PreviewData.session(0)) } }
}
#endif
