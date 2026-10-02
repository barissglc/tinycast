import AppKit
import Carbon.HIToolbox

/// The palette's keyboard belongs to the search field, and a preview's transport may never take it.
@main
@MainActor
struct KeyboardFocusTests {
    static var failures = 0
    static var passes = 0

    static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        if condition() {
            passes += 1
        } else {
            failures += 1
            print("FAIL: \(message)")
        }
    }

    /// Stands in for the player surface: what the mark means is "nothing under here takes focus".
    final class MarkedView: NSView, KeyboardFocusRefusing {}

    static func main() {
        theMarkedViewRefuses()
        aDescendantOfTheMarkRefuses()
        everythingElseAccepts()
        dialogReturnBelongsToTheEditor()

        print("\(passes) passed, \(failures) failed")
        if failures > 0 { exit(1) }
    }

    static func theMarkedViewRefuses() {
        expect(MarkedView().refusesKeyboardFocus, "the marked view itself refuses focus")
    }

    /// The real offender is `AVDesktopButton`, a private control the transport owns.
    static func aDescendantOfTheMarkRefuses() {
        let marked = MarkedView()
        let button = NSButton()
        let bar = NSView()
        bar.addSubview(button)
        marked.addSubview(bar)
        expect(button.refusesKeyboardFocus, "a control nested under the mark refuses focus too")
    }

    static func everythingElseAccepts() {
        let root = NSView()
        let field = NSTextField()
        let marked = MarkedView()
        root.addSubview(field)
        root.addSubview(marked)
        expect(!field.refusesKeyboardFocus, "a sibling of the mark still takes focus")
        expect(!root.refusesKeyboardFocus, "an ancestor of the mark still takes focus")
        expect(!NSView().refusesKeyboardFocus, "an unparented view takes focus")
    }

    static func dialogReturnBelongsToTheEditor() {
        _ = NSApplication.shared
        let panel = DialogPanel(
            content: NSView(frame: NSRect(x: 0, y: 0, width: 100, height: 100)), cornerRadius: 10)
        var keys: [DialogPanel.Key] = []
        panel.onKey = { keys.append($0) }
        send(kVK_Return, to: panel)
        expect(keys == [.confirm], "ordinary dialogs confirm on Return")
        keys = []
        panel.requiresCommandReturn = true
        send(kVK_Return, to: panel)
        send(kVK_Return, flags: .shift, to: panel)
        send(kVK_ANSI_KeypadEnter, to: panel)
        expect(keys.isEmpty, "Return and keypad Enter do not save a multiline draft")
        send(kVK_Return, flags: .command, to: panel)
        send(kVK_ANSI_KeypadEnter, flags: .command, to: panel)
        expect(keys == [.confirm, .confirm], "Command-Return saves the draft")
        keys = []
        send(kVK_LeftArrow, to: panel)
        send(kVK_DownArrow, to: panel)
        expect(keys.isEmpty, "text editing retains caret arrows")
        send(kVK_Escape, to: panel)
        expect(keys == [.cancel], "Escape still cancels the draft")
        panel.onKey = nil
        panel.close()
    }

    static func send(_ code: Int, flags: NSEvent.ModifierFlags = [], to panel: DialogPanel) {
        let event = NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: flags, timestamp: 0,
            windowNumber: panel.windowNumber, context: nil, characters: "\r",
            charactersIgnoringModifiers: "\r", isARepeat: false, keyCode: UInt16(code))!
        panel.sendEvent(event)
    }
}
