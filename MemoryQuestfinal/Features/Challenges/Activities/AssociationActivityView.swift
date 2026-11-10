import SwiftUI

struct StoryActivityView: View {
    @Bindable var model: ChallengeSessionViewModel
    var body: some View {
        VStack(alignment:.leading,spacing:18) {
            PageTitle(text:"Make it memorable")
            Text(model.storyTerms.joined(separator:" · ")).font(.headline)
            QuestCard { Text("A guided example").font(.caption).foregroundStyle(AppTheme.muted); Text(model.content.story) }
            Text("Write your own story using all \(model.storyTerms.count) concepts")
            AnswerField(text:$model.story,prompt:"Picture a scene and connect the four concepts…",multiline:true)
            Text("The keyword check only confirms that you used the target words. It does not assess conceptual understanding.").font(.caption).foregroundStyle(AppTheme.muted)
            QuestButton(title:"Hide my story & recall") { model.hideStory() }
        }
    }
}
struct LinkingActivityView: View {
    @Bindable var model: ChallengeSessionViewModel
    var body: some View {
        VStack(alignment:.leading,spacing:18) {
            PageTitle(text:"Make the connection")
            Text("Select the familiar analogy for each concept. Explain the link to yourself.").font(.subheadline)
            ForEach(model.links.indices, id: \.self) { i in
                QuestCard {
                    Text(model.links[i].term).font(.headline)
                    Picker("Choose an analogy",selection:Binding(get:{ model.groups[i,default: -1] },set:{ model.groups[i]=$0 })) {
                        Text("Choose an analogy").tag(-1)
                        ForEach(Array(model.links.indices.reversed()),id:\.self) { k in Text(model.links[k].cue).tag(k) }
                    }.disabled(model.feedback != nil)
                }
            }
            if model.feedback == nil { QuestButton(title:"Check the links") { model.checkLinks() } }
        }
    }
}

#if DEBUG
#Preview("StoryActivityView") {
    PreviewScreen() { QuestPage { StoryActivityView(model: PreviewData.session(4)) } }
}

#Preview("LinkingActivityView") {
    PreviewScreen() { QuestPage { LinkingActivityView(model: PreviewData.session(5)) } }
}
#endif
