import SwiftUI

struct LessonBodyView: View {
    let page: LessonPage
    let color: Color
    var body: some View {
        VStack(alignment:.leading,spacing:18) {
            if let blocks=page.blocks {
                ForEach(blocks) { block in
                    LessonBodyBlock(block:block,color:color)
                }
            } else {
                Text(page.body).lineSpacing(6).fixedSize(horizontal:false,vertical:true)
            }
        }
    }
}
struct LessonBodyBlock: View {
    let block: LessonBlock
    let color: Color
    var body: some View {
        VStack(alignment:.leading,spacing:0) {
            if block.kind == "flow" {
                HStack(spacing:8) {
                    ForEach(block.text.split(separator:"|"),id:\.self) { item in
                        Text(String(item)).padding(12).background(AppTheme.surface,in:RoundedRectangle(cornerRadius:8)).overlay(RoundedRectangle(cornerRadius:8).stroke(AppTheme.line))
                    }
                }
            } else {
                let text=(try? AttributedString(markdown:block.text,options:.init(interpretedSyntax:.inlineOnlyPreservingWhitespace))) ?? AttributedString(block.text)
                Text(text).lineSpacing(6).fixedSize(horizontal:false,vertical:true)
                    .foregroundStyle(block.kind == "callout" ? LessonPresentation.textOnPastel : AppTheme.ink)
                    .padding(block.kind == "callout" ? 16 : 0)
                    .frame(maxWidth:.infinity,alignment:.leading)
                    .background(block.kind == "callout" ? color : .clear,in:RoundedRectangle(cornerRadius:12))
            }
        }
    }
}

#if DEBUG
#Preview("LessonBodyView") {
    PreviewScreen() { LessonBodyView(page: ContentRepository.lessons[0].pages[0], color: .purple.opacity(0.1)) }
}

#Preview("LessonBodyBlock") {
    PreviewScreen() { LessonBodyBlock(block: LessonBlock(id: "preview", kind: "callout", text: "Retrieve an idea before checking your notes."), color: .purple.opacity(0.1)) }
}
#endif
