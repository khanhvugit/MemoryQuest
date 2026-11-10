import SwiftUI

struct RetrievalActivityView: View {
    @Bindable var model: ChallengeSessionViewModel
    var body: some View {
        VStack(alignment:.leading,spacing:20) {
            if model.stage == "groupRecall" {
                PageTitle(text:"Recall the group")
                Text("The grouped list is hidden. Use the group name as a cue.").font(.subheadline).foregroundStyle(AppTheme.muted)
                Text("Name two members of \(model.content.categories[model.index]).").font(.title3)
            } else if model.id == 4 {
                PageTitle(text:"What was in your story?")
                Text("The story and concept list are hidden. Retrieve all four original \(model.subject.title) terms.")
            } else if model.id == 5 {
                PageTitle(text:"Retrieve the concept")
                QuestCard { Text("Which concept matches this analogy?").font(.caption); Text(model.content.links[model.index].cue).font(.title3) }
            } else {
                let item=model.deck[model.index]
                if [6,7].contains(model.id) {
                    if let date=item.lastSeen { Text("Your history · last seen \(date.formatted(date:.abbreviated,time:.omitted))").font(.caption) }
                    else { Text("Sample history · introductory practice, not your past performance").font(.caption).foregroundStyle(AppTheme.muted) }
                }
                if model.id == 7 { Text("\(model.rescued.count) memories rescued").font(.caption) }
                PageTitle(text:model.id == 7 ? "Rescue this memory" : model.id == 6 ? "Welcome back, memory" : "Retrieve the term")
                QuestCard { Text("Definition").font(.caption).foregroundStyle(AppTheme.muted); Text(item.concept.def).font(.title3) }
                if model.difficulty == .easy && model.feedback == nil {
                    Button("Show a retrieval cue") { model.hint=true }
                    if model.hint { Text(item.concept.hint).font(.subheadline) }
                }
            }
            AnswerField(text:$model.answer,prompt:[2,4].contains(model.id) ? "Separate the concepts with commas" : "Your answer").disabled(model.feedback != nil)
            if model.feedback == nil { QuestButton(title:"Check answer",disabled:!model.canCheck) { model.check() } }
        }
    }
}
struct FlashcardActivityView: View {
    @Bindable var model: ChallengeSessionViewModel
    var body: some View {
        VStack(alignment:.leading,spacing:20) {
            PageTitle(text:"Retrieve before you flip")
            Button { model.flipped=true } label: {
                QuestCard {
                    Text(model.flipped ? model.deck[model.index].concept.def : model.deck[model.index].concept.term).font(.title2).frame(maxWidth:.infinity).padding(.vertical,40)
                    Text(model.flipped ? "Compare with the definition you recalled." : "Explain it to yourself, then tap to flip.").font(.caption).foregroundStyle(AppTheme.muted)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(model.flipped ? "Definition shown" : "Flashcard: \(model.deck[model.index].concept.term)")
            .accessibilityValue(model.flipped ? model.deck[model.index].concept.def : "")
            .accessibilityHint(model.flipped ? "Compare with the definition you recalled." : "Recall the definition, then double tap to reveal it.")
            if model.flipped { HStack { QuestButton(title:"Need practice",secondary:true) { model.selfRate(false) }; QuestButton(title:"I recalled it") { model.selfRate(true) } } }
            Text("Self-assessment · Be honest about the key idea.").font(.caption).foregroundStyle(AppTheme.muted)
        }
    }
}
