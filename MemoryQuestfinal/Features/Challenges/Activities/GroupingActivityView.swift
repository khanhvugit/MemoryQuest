import SwiftUI

struct GroupingActivityView: View {
    @Bindable var model: ChallengeSessionViewModel
    var body: some View {
        VStack(alignment:.leading,spacing:18) {
            PageTitle(text:"Give every term a home")
            Text("Group by meaning. You will retrieve these groups after checking.").font(.subheadline)
            QuestCard {
                ForEach(model.groupedTerms.indices, id: \.self) { i in
                    VStack(alignment:.leading) {
                        Text(model.groupedTerms[i].term).font(.headline)
                        Picker("Category",selection:Binding(get:{ model.groups[i,default: -1] },set:{ model.groups[i]=$0 })) {
                            Text("Choose category").tag(-1)
                            ForEach(0..<3) { category in Text(model.content.categories[category]).tag(category) }
                        }.disabled(model.feedback != nil)
                    }
                }
            }
            if model.feedback == nil { QuestButton(title:"Check my groups") { model.checkGroups() } }
        }
    }
}
struct SequenceActivityView: View {
    @Bindable var model: ChallengeSessionViewModel
    var body: some View {
        VStack(alignment:.leading,spacing:18) {
            PageTitle(text:"Rebuild the process")
            Text("Rebuild this part of the process in its original order.").font(.subheadline)
            QuestCard {
                if model.order.isEmpty { Text("Your sequence will appear here.").foregroundStyle(AppTheme.muted) }
                ForEach(Array(model.order.enumerated()),id:\.element) { i,selection in Text("\(i+1). \(model.currentSequence[selection])") }
            }
            ForEach(Array(model.currentSequence.indices.reversed()),id:\.self) { i in
                QuestButton(title:model.currentSequence[i],secondary:true,disabled:model.order.contains(i) || model.feedback != nil) { model.order.append(i) }
            }
            if model.feedback == nil {
                QuestButton(title:"Undo last step",secondary:true,disabled:model.order.isEmpty) { _ = model.order.popLast() }
                QuestButton(title:"Check sequence",disabled:model.order.count != model.currentSequence.count) { model.checkSequence() }
            }
        }
    }
}

#if DEBUG
#Preview("GroupingActivityView") {
    PreviewScreen() { QuestPage { GroupingActivityView(model: PreviewData.session(2)) } }
}

#Preview("SequenceActivityView") {
    PreviewScreen() { QuestPage { SequenceActivityView(model: PreviewData.session(3)) } }
}
#endif
