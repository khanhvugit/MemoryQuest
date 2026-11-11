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
            HStack(spacing:6) { ForEach(0..<5) { i in Capsule().fill(i <= model.step ? LessonPresentation.foreground(for: lesson) : AppTheme.line).frame(height:4) } }.accessibilityLabel("Step \(model.step+1) of 5")
            PageTitle(text:page.title)
            if model.step == 2 { LessonDemonstration(id:id,subject:store.progress.subject,page:page,model:model) }
            else { LessonBodyView(page:page,color:LessonPresentation.background(for: lesson)) }
            if model.step == 3 { GuidedPractice(id:id,subject:store.progress.subject,model:model) }
            if model.step == 4 { Text(lesson.routine).foregroundStyle(LessonPresentation.textOnPastel).padding(16).frame(maxWidth:.infinity,alignment:.leading).background(LessonPresentation.background(for: lesson),in:RoundedRectangle(cornerRadius:12)) }
            HStack {
                if model.step > 0 { QuestButton(title:"Previous",secondary:true) { move(model.step-1) } }
                QuestButton(title:model.step == 4 ? "Complete lesson" : "Next",disabled:model.step == 3 && !model.passed) {
                    if model.step == 4 { store.progress.completedLessons.insert(id); store.progress.lessonSteps[id] = 0; store.save(); app.path.removeLast(); app.path.append(.lessonComplete(id)) }
                    else { move(model.step+1) }
                }
            }.padding(.top,12)
        }.id(model.step).navigationTitle("Lesson \(id+1)")
            .tint(LessonPresentation.foreground(for: lesson))
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
    private var revealedText: String {
        let biology: [String] = ["A ribosome builds the polypeptide by reading messenger RNA.","Cell Structures: Nucleus, Ribosome, Mitochondrion. Biomolecules: Protein, Lipid, Carbohydrate. Transport: Diffusion, Osmosis, Active transport.","Which structure reads the working copy of a gene? A ribosome reads messenger RNA.","Missed Osmosis today? Check water movement now and retrieve it tomorrow. Adjust the planned interval.","Ions move against a concentration gradient → Active transport. Explain why energy is required."]
        let computerScience: [String] = ["C comes off first, because it was added last. Stack = LIFO.","Can you name three data structures without the list? Stack, Queue, and Array are one meaningful chunk.","In a printer queue, which job should be handled first? The earliest job added.","Missed Queue today? Check FIFO now and schedule another retrieval tomorrow. Do not wait for a longer interval just because it was planned.","Customer support requests served in arrival order → Queue. Explain FIFO to justify the choice."]
        return subject == .biology ? biology[id] : computerScience[id]
    }
    var body: some View {
        VStack(alignment:.leading,spacing:18) {
            if !model.revealed || ![0,1].contains(id) { LessonBodyView(page:page,color:LessonPresentation.background(for: ContentRepository.lessons[id])) }
            else { Text(id == 0 ? "Definition hidden. Retrieve the rule first, then check the answer below." : "The groups are hidden. Can you reconstruct them?") }
            if id == 3 {
                LazyVGrid(columns:Array(repeating:GridItem(.flexible()),count:7)) { ForEach(1..<15) { day in Text("\(day)").foregroundStyle([1,2,4,7].contains(day) ? LessonPresentation.textOnPastel : AppTheme.ink).frame(maxWidth:.infinity).padding(8).background([1,2,4,7].contains(day) ? LessonPresentation.background(for: ContentRepository.lessons[id]) : AppTheme.surface,in:RoundedRectangle(cornerRadius:6)) } }
            }
            if model.revealed {
                Text(revealedText)
                    .foregroundStyle(LessonPresentation.textOnPastel)
                    .padding(16).background(LessonPresentation.background(for: ContentRepository.lessons[id]),in:RoundedRectangle(cornerRadius:12))
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
    private var hintText: String {
        if id == 3 { return "Read the sample sequence again: 1, 2, 4, 7." }
        let biology: [String] = ["Think of the protein-building workshop.","Cell structures perform jobs within cells.","Which analogy involves assembling a chain?","","Include catalysis and not being consumed."]
        let computerScience: [String] = ["Think of plates: last on, first off.","Data structures organise collections of elements.","Think about the last plate you put on top.","","Include both what it is and why it is useful."]
        return subject == .biology ? biology[id] : computerScience[id]
    }
    var body: some View {
        QuestCard {
            if id == 0 { Text("Your answer"); AnswerField(text:$model.answer,prompt:subject == .biology ? "Type the cell structure" : "Type the data structure") }
            else { ForEach(Array(choices.enumerated()),id:\.element) { i,choice in ChoiceButton(title:choice,selected:model.choice == i, accent: LessonPresentation.foreground(for: ContentRepository.lessons[id])) { model.choice = i } } }
            QuestButton(title:"Check my answer",secondary:true,disabled:id == 0 ? model.answer.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty : model.choice < 0) { model.check(id:id,subject:subject) }
            Button("Show a hint") { model.hint = true }.foregroundStyle(LessonPresentation.foreground(for: ContentRepository.lessons[id]))
            if model.hint { Text(hintText).font(.subheadline).foregroundStyle(AppTheme.muted) }
            if let feedback = model.feedback { FeedbackView(text:feedback,correct:model.passed) }
        }
    }
}
struct ChoiceButton: View {
    let title: String
    let selected: Bool
    var accent: Color = AppTheme.coral
    let action: () -> Void
    var body: some View { Button(action:action) { HStack { Text(title).multilineTextAlignment(.leading); Spacer() }.padding(14).frame(maxWidth:.infinity,alignment:.leading).background(selected ? accent.opacity(0.12) : AppTheme.surface,in:RoundedRectangle(cornerRadius:10)).overlay(RoundedRectangle(cornerRadius:10).stroke(selected ? accent : AppTheme.line)) }.buttonStyle(.plain).accessibilityAddTraits(selected ? .isSelected : []) }
}
struct LessonCompleteView: View {
    let id: Int
    @Environment(AppState.self) private var app
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 32) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 86, weight: .regular))
                        .foregroundStyle(Color(hex: "24C83F"))
                        .frame(width: 190, height: 190)
                        .background(Color(hex: "D9F5DE"), in: Circle())
                        .overlay {
                            LessonConfettiView()
                                .frame(width: 440, height: 400)
                                .allowsHitTesting(false)
                                .accessibilityHidden(true)
                        }
                        .accessibilityHidden(true)
                    Text("Lesson Complete!")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, max(40, geometry.size.height * 0.16))
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                QuestButton(title: "Back to home", secondary: true) { app.navigate(.home) }
                QuestButton(title: "Go to challenge") { app.navigate(.challenges) }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
            .background(AppTheme.background)
        }
        .background(AppTheme.background)
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct LessonConfettiView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startDate = Date()
    @State private var isAnimating = true

    private static let duration: TimeInterval = 1.8
    private static let pieces: [ConfettiPiece] = (0..<172).map(makePiece)

    nonisolated private static func makePiece(id: Int) -> ConfettiPiece {
        let isCentral = id.isMultiple(of: 3)
        let angleDegrees = isCentral
            ? -105 + Double((id * 17) % 31)
            : -165 + Double((id * 47) % 151)
        let speed = isCentral
            ? CGFloat(48 + (id * 13) % 42)
            : CGFloat(125 + (id * 31) % 105)
        return ConfettiPiece(
            id: id,
            angle: angleDegrees * .pi / 180,
            speed: speed,
            delay: Double(id % 7) * 0.014,
            width: CGFloat(3 + id % 4),
            height: CGFloat(6 + id % 5),
            isRound: id.isMultiple(of: 6)
        )
    }

    var body: some View {
        if !reduceMotion {
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !isAnimating)) { timeline in
                Canvas { context, size in
                    let elapsed = timeline.date.timeIntervalSince(startDate)
                    for piece in Self.pieces {
                        let time = elapsed - piece.delay
                        guard time >= 0, time <= Self.duration else { continue }

                        let origin = CGPoint(x: size.width / 2, y: size.height / 2)
                        let horizontalTravel = cos(piece.angle) * Double(piece.speed) * time
                        let verticalTravel = sin(piece.angle) * Double(piece.speed) * time + 105 * time * time
                        let center = CGPoint(
                            x: origin.x + CGFloat(horizontalTravel),
                            y: origin.y + CGFloat(verticalTravel)
                        )
                        let frame = CGRect(
                            x: center.x - piece.width / 2,
                            y: center.y - piece.height / 2,
                            width: piece.width,
                            height: piece.height
                        )
                        let path = piece.isRound
                            ? Path(ellipseIn: frame)
                            : Path(roundedRect: frame, cornerRadius: 2)
                        let opacity = max(0, 1 - time / Self.duration)
                        context.fill(path, with: .color(piece.color.opacity(opacity * 0.62)))
                    }
                }
            }
            .task {
                try? await Task.sleep(for: .seconds(Self.duration))
                isAnimating = false
            }
        }
    }
}

private struct ConfettiPiece: Identifiable {
    let id: Int
    let angle: Double
    let speed: CGFloat
    let delay: TimeInterval
    let width: CGFloat
    let height: CGFloat
    let isRound: Bool

    var color: Color {
        switch id % 6 {
        case 0: Color(hex: "2CC85A")
        case 1: Color(hex: "168BF2")
        case 2: Color(hex: "54C4E8")
        case 3: Color(hex: "FFCC18")
        case 4: Color(hex: "FF8A16")
        default: Color(hex: "F52F68")
        }
    }
}

#if DEBUG
#Preview("LessonReaderView") {
    PreviewScreen() { LessonReaderView(id: 0) }
}

#Preview("LessonDemonstration") {
    PreviewScreen() { LessonDemonstration(id: 0, subject: .computerScience, page: ContentRepository.lessons[0].pages[2], model: LessonViewModel(step: 2)) }
}

#Preview("GuidedPractice") {
    PreviewScreen() { GuidedPractice(id: 0, subject: .computerScience, model: LessonViewModel(step: 3)) }
}

#Preview("ChoiceButton") {
    PreviewScreen() { ChoiceButton(title: "Stack", selected: true, action: {}) }
}

#Preview("LessonCompleteView") {
    PreviewScreen() { LessonCompleteView(id: 0) }
}
#endif

