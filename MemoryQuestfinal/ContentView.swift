import SwiftUI

struct ContentView: View {
    var store: ProgressStore?
    var body: some View { RootView(store: store) }
}

#if DEBUG
#Preview("ContentView") {
    ContentView(store: PreviewData.store())
}
#endif
