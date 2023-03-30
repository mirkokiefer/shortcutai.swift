import Foundation
import CoreGraphics
import Carbon
import AppKit

func simulateKeyboardPress(characterSequence: String, withModifiers: CGEventFlags = []) {
    for character in characterSequence {
        if let unicodeScalar = character.unicodeScalars.first {
            let unicharValue = UInt16(unicodeScalar.value)
            if let keyCodeAndModifiers = characterToKeyCodeAndModifiers(unicharValue) {
                pressKey(keyCode: keyCodeAndModifiers.keyCode, modifiers: keyCodeAndModifiers.modifiers.union(withModifiers))
            }
        }
    }
}

func pressKey(keyCode: CGKeyCode, modifiers: CGEventFlags = []) {
    let keyDownEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)!
    keyDownEvent.flags = modifiers
    keyDownEvent.post(tap: .cghidEventTap)

    let keyUpEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)!
    keyUpEvent.flags = modifiers
    keyUpEvent.post(tap: .cghidEventTap)
}

func characterToKeyCodeAndModifiers(_ character: unichar) -> (keyCode: CGKeyCode, modifiers: CGEventFlags)? {
    var deadKeyState: UInt32 = 0
    let maxChars = 4
    var chars = [UniChar](repeating: 0, count: maxChars)
    var keyCode: Int = 0

    let keyboardLayout = TISCopyCurrentKeyboardLayoutInputSource().takeUnretainedValue()
    let layoutData = TISGetInputSourceProperty(keyboardLayout, kTISPropertyUnicodeKeyLayoutData)
    let dataRef = unsafeBitCast(layoutData, to: CFData.self)
    let keyLayout = unsafeBitCast(CFDataGetBytePtr(dataRef), to: UnsafePointer<UCKeyboardLayout>.self)

    let error = UCKeyTranslate(
        keyLayout,
        UInt16(character),
        UInt16(kUCKeyActionDisplay),
        0,
        UInt32(LMGetKbdType()),
        OptionBits(kUCKeyTranslateNoDeadKeysBit),
        &deadKeyState,
        maxChars,
        &keyCode,
        &chars
    )

    if error == noErr {
        return (CGKeyCode(keyCode), [])
    }

    return nil
}

func simulateBackspaceKeyPress() {
    let backspaceKeyCode: CGKeyCode = 51
    pressKey(keyCode: backspaceKeyCode, modifiers: [])
}

func copyToPasteboard(text: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)
}

func simulatePasteKeyPress() {
    let vKeyCode: CGKeyCode = 9
    pressKey(keyCode: vKeyCode, modifiers: .maskCommand)
}

func generateRandomWord() -> String {
    let wordLength = Int.random(in: 3...10)
    let alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    let randomWord = (0..<wordLength).map { _ in alphabet.randomElement()! }
    return String(randomWord)
}

let typingQueue = DispatchQueue(label: "com.example.typingQueue")

let timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
        typingQueue.async {
            let randomWord = generateRandomWord()
            print("Typing random word: \(randomWord)")
            let spaced = " \(randomWord)"
            copyToPasteboard(text: spaced)
            simulatePasteKeyPress()
        }
    }

// Add signal handler for SIGINT
var signalInterrupt = false
let signalHandler: @convention(c) (Int32) -> Void = { _ in
    signalInterrupt = true
    timer.invalidate()
    CFRunLoopStop(CFRunLoopGetCurrent())
}
signal(SIGINT, signalHandler)

// Run the main run loop until a signal interrupt occurs
while !signalInterrupt {
    RunLoop.current.run(mode: .default, before: .distantFuture)
}
