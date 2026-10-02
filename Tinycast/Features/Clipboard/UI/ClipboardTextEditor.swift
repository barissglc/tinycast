import SwiftUI

@MainActor
@Observable
final class ClipboardTextEditState {
    var text: String
    var isPresented = false

    init(text: String) {
        self.text = text
    }
}

struct ClipboardTextEditor: View {
    @Environment(\.metrics) private var metrics
    @Bindable var state: ClipboardTextEditState
    @FocusState private var focused: Bool

    var body: some View {
        TextEditor(text: $state.text)
            .font(.system(.body, design: .monospaced))
            .scrollContentBackground(.hidden)
            .focused($focused)
            .padding(metrics.spacing.sm)
            .frame(height: Theme.Size.editorTextHeight)
            .background(
                RoundedRectangle(cornerRadius: metrics.radius.row, style: .continuous)
                    .fill(Theme.Colors.controlSurface)
            )
            .accessibilityLabel("Pinned clipboard text")
            .onChange(of: state.isPresented, initial: true) { _, presented in
                focused = presented
            }
    }
}
