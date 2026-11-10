import SwiftUI

struct LessonReaderView: View {
    let id: Int
    @Environment(ProgressStore.self) private var store
    @Environment(AppState.self) private var app
    @State private var model = LessonViewModel(step:0)
    @State private var loaded = false
    var body: some View {
        let lesson = ContentRepository.lessons[id]
        let page = ContentRepository.page(lesson:id,step:model.step,subject:store.progress.subject)
        QuestPage {
            HStack(spacing:6) { ForEach(0..<5) { i in Capsule().fill(i <= model.step ? Color(hex:lesson.deep) : AppTheme.line).frame(height:4) } }.accessibilityLabel("Step \(model.step+1) of 5")
            Text("STEP \(model.step+1) OF 5 · \(["DISCOVER","UNDERSTAND","DEMONSTRATION","GUIDED PRACTICE","APPLY"][model.step])").font(.caption.weight(.semibold)).tracking(1.5).foregroundStyle(AppTheme.muted)
            PageTitle(text:page.title)
            if model.step == 2 { LessonDemonstration(id:id,subject:store.progress.subject,page:page,model:model) }
            else { LessonBodyView(page:page,color:Color(hex:lesson.soft)) }
            if model.step == 3 { GuidedPractice(id:id,subject:store.progress.subject,model:model) }
            if model.step == 4 { Text(lesson.routine).padding(16).frame(maxWidth:.infinity,alignment:.leading).background(Color(hex:lesson.soft),in:RoundedRectangle(cornerRadius:12)) }
            HStack {
                if model.step > 0 { QuestButton(title:"Previous",secondary:true) { move(model.step-1) } }
                QuestButton(title:model.step == 4 ? "Complete lesson" : "Next",disabled:model.step == 3 && !model.passed) {
                    if model.step == 4 { guard app.path.last == .reader(id) else { return }; store.progress.completedLessons.insert(id); store.progress.lessonSteps[id] = 0; store.save(); app.path[app.path.count - 1] = .lessonComplete(id) }
                    else { move(model.step+1) }
                }
            }.padding(.top,12)
        }.id(model.step).navigationTitle("Lesson \(id+1)")
            .onAppear { if !loaded { model.step = store.progress.completedLessons.contains(id) ? 0 : store.progress.lessonSteps[id,default:0]; loaded = true } }
            .onChange(of:store.progress.subject) { model.resetPractice() }
    }
    private func move(_ step: Int) { model.move(step); store.progress.lessonSteps[id] = step; store.save() }
}
struct LessonDemonstration: View {
    let id: Int
    let subject: Subject
    let page: LessonPage
    @Bindable var model: LessonViewModel
    var body: some View {
        VStack(alignment:.leading,spacing:18) {
            if !model.revealed || ![0,1].contains(id) { LessonBodyView(page:page,color:Color(hex:ContentRepository.lessons[id].soft)) }
            else { Text(id == 0 ? "Definition hidden. Retrieve the rule first, then check the answer below." : "The groups are hidden. Can you reconstruct them?") }
            if id == 3 {
                LazyVGrid(columns:Array(repeating:GridItem(.flexible()),count:7)) { ForEach(1..<15) { day in Text("\(day)").frame(maxWidth:.infinity).padding(8).background([1,2,4,7].contains(day) ? Color(hex:"e4f4e3") : .white,in:RoundedRectangle(cornerRadius:6)) } }
            }
            if model.revealed {
                Text(subject == .biology ? ["A ribosome builds the polypeptide by reading messenger RNA.","Cell Structures: Nucleus, Ribosome, Mitochondrion. Biomolecules: Protein, Lipid, Carbohydrate. Transport: Diffusion, Osmosis, Active transport.","Which structure reads the working copy of a gene? A ribosome reads messenger RNA.","Missed Osmosis today? Check water movement now and retrieve it tomorrow. Adjust the planned interval.","Ions move against a concentration gradient → Active transport. Explain why energy is required."][id] : ["C comes off first, because it was added last. Stack = LIFO.","Can you name three data structures without the list? Stack, Queue, and Array are one meaningful chunk.","In a printer queue, which job should be handled first? The earliest job added.","Missed Queue today? Check FIFO now and schedule another retrieval tomorrow. Do not wait for a longer interval just because it was planned.","Customer support requests served in arrival order → Queue. Explain FIFO to justify the choice."][id])
                    .padding(16).background(Color(hex:ContentRepository.lessons[id].soft),in:RoundedRectangle(cornerRadius:12))
            } else {
                QuestButton(title:["Hide definition & reveal the answer","Hide the groups & test yourself","Reveal a self-check question","Reveal a review decision","Reveal another application"][id],secondary:true) { model.revealed = true }
            }
        }
    }
}
struct GuidedPractice: View {
    let id: Int
    let subject: Subject
    @Bindable var model: LessonViewModel
    var choices: [String] {
        if id == 3 { return ["Day 3","Day 4","Day 7"] }
        if subject == .biology {
            return [[],["Nucleus, Ribosome, Mitochondrion","Protein, Osmosis, Nucleus","Lipid, Diffusion, Ribosome"],["An assembly workshop: joins amino acids using instructions","An archive: stores most DNA","A gate: regulates passage"],[],["An enzyme helps things","An enzyme is a biological catalyst that speeds a reaction without being consumed","An enzyme stores all genetic information"]][id]
        }
        return [[],["Stack, Queue, Array","If, Boolean, Stack","String, Queue, While"],["A stack of plates: last placed, first removed","A queue of people: first arrived, first served","An unordered bag: remove any item"],[],["A function does stuff","A function is a reusable block of code for a specific task","A function always stores items in arrival order"]][id]
    }
    var body: some View {
        QuestCard {
            if id == 0 { Text("Your answer"); AnswerField(text:$model.answer,prompt:subject == .biology ? "Type the cell structure" : "Type the data structure") }
            else { ForEach(Array(choices.enumerated()),id:\.element) { i,choice in ChoiceButton(title:choice,selected:model.choice == i) { model.choice = i } } }
            QuestButton(title:"Check my answer",secondary:true,disabled:id == 0 ? model.answer.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty : model.choice < 0) { model.check(id:id,subject:subject) }
            Button("Show a hint") { model.hint = true }.foregroundStyle(Color(hex:ContentRepository.lessons[id].deep))
            if model.hint { Text(id == 3 ? "Read the sample sequence again: 1, 2, 4, 7." : (subject == .biology ? ["Think of the protein-building workshop.","Cell structures perform jobs within cells.","Which analogy involves assembling a chain?","","Include catalysis and not being consumed."][id] : ["Think of plates: last on, first off.","Data structures organise collections of elements.","Think about the last plate you put on top.","","Include both what it is and why it is useful."][id])).font(.subheadline).foregroundStyle(AppTheme.muted) }
            if let feedback = model.feedback { FeedbackView(text:feedback,correct:model.passed) }
        }
    }
}
struct ChoiceButton: View {
    let title: String
    let selected: Bool
    let action: () -> Void
    var body: some View { Button(action:action) { HStack { Text(title).multilineTextAlignment(.leading); Spacer(); if selected { Image(systemName:"checkmark.circle.fill") } }.padding(14).frame(maxWidth:.infinity,alignment:.leading).background(selected ? AppTheme.coral.opacity(0.12) : .white,in:RoundedRectangle(cornerRadius:10)).overlay(RoundedRectangle(cornerRadius:10).stroke(selected ? AppTheme.coral : AppTheme.line)) }.buttonStyle(.plain).accessibilityAddTraits(selected ? .isSelected : []) }
}
struct LessonCompleteView: View {
    let id: Int
    @Environment(AppState.self) private var app
    var body: some View {
        QuestPage {
            Image(systemName:"checkmark.circle").font(.system(size:64)).foregroundStyle(.green).frame(maxWidth:.infinity).padding(.top,30)
            PageTitle(text:"Lesson Complete!")
            Text("You explored \(ContentRepository.lessons[id].title.lowercased()).")
            QuestCard { Text(ContentRepository.lessons[id].routine) }
            Text("Now put the strategy to work. Each completed challenge adds a building to your city.").foregroundStyle(AppTheme.muted)
            QuestButton(title:"Back to home",secondary:true) { app.navigate(.home) }
            QuestButton(title:"Go to challenges") { app.navigate(.challenges) }
        }.navigationBarBackButtonHidden()
    }
}
