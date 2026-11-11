import SwiftUI

struct ExplanationActivityView: View {
    @Bindable var model: ChallengeSessionViewModel
    var body: some View {
        VStack(alignment:.leading,spacing:18) {
            Image(systemName:"desktopcomputer").font(.system(size:44)).foregroundStyle(Color(hex:"ae7b16"))
            PageTitle(text:model.robots[model.index].q)
            Text("Explain from memory. The robot checks for predefined key ideas.").font(.subheadline).foregroundStyle(AppTheme.muted)
            Text("Your explanation")
            AnswerField(text:$model.answer,prompt:"Use your own words…",multiline:true).disabled(model.feedback != nil)
            if model.feedback == nil { QuestButton(title:"Check my explanation",disabled:!model.canCheck) { model.check() } }
            Text("Rule-based checklist feedback, not an AI assessment. Wording can affect which ideas are detected.").font(.caption).foregroundStyle(AppTheme.muted)
        }
    }
}
struct DetectiveActivityView: View {
    @Bindable var model: ChallengeSessionViewModel
    var body: some View {
        let question=model.detectives[model.index]
        VStack(alignment:.leading,spacing:18) {
            PageTitle(text:"Follow the evidence")
            Text(question.q).font(.title3)
            ForEach(Array(question.opts.enumerated()),id:\.element) { i,option in ChoiceButton(title:option,selected:model.choice == i) { model.choice=i }.disabled(model.feedback != nil) }
            if model.feedback == nil { QuestButton(title:"Check answer",disabled:model.choice < 0) { model.check() } }
        }
    }
}

#if DEBUG
#Preview("ExplanationActivityView") {
    PreviewScreen() { QuestPage { ExplanationActivityView(model: PreviewData.session(8)) } }
}

#Preview("DetectiveActivityView") {
    PreviewScreen() { QuestPage { DetectiveActivityView(model: PreviewData.session(9)) } }
}
#endif
