import Foundation
import AppKit
import CoreGraphics
import ApplicationServices
import Carbon

func getUnicodeString(from event: CGEvent) -> String {
    let maxLength = 64
    var chars = [UniChar](repeating: 0, count: maxLength)
    var actualLength: Int = 0

    event.keyboardGetUnicodeString(maxStringLength: maxLength, actualStringLength: &actualLength, unicodeString: &chars)

    let unicodeString = String(utf16CodeUnits: chars, count: actualLength)
    return unicodeString
}

func getModifierKeys(from event: CGEvent) -> String {
    var modifierKeys = ""
    let flags = event.flags

    if flags.contains(.maskCommand) {
        modifierKeys += "⌘"
    }
    if flags.contains(.maskShift) {
        modifierKeys += "⇧"
    }
    if flags.contains(.maskAlternate) {
        modifierKeys += "⌥"
    }
    if flags.contains(.maskControl) {
        modifierKeys += "⌃"
    }

    return modifierKeys
}

// Class to listen to global keyboard events
class GlobalKeyListener {
    private var lastThreeCharacters: String = ""
    private var eventTap: CFMachPort?

    // Function to start listening to keyboard events
    func startListening() {
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
        let userInfo = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        guard let eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap,
                                               place: .headInsertEventTap,
                                               options: .defaultTap,
                                               eventsOfInterest: CGEventMask(eventMask),
                                               callback: eventTapCallback,
                                               userInfo: userInfo) else {
            print("Failed to create event tap")
            return
        }

        self.eventTap = eventTap

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
    }

    // Function to stop listening to keyboard events
    func stopListening() {
        if let eventTap = eventTap {
            CFMachPortInvalidate(eventTap)
            self.eventTap = nil
        }
    }

    // Function to process a key event
    private func processKeyEvent(_ event: CGEvent) {
    let unicodeString = getUnicodeString(from: event)
    let modifierKeys = getModifierKeys(from: event)

    print("Character typed: \(modifierKeys) \(unicodeString)")
}

    // Callback function for the key event tap
    private let eventTapCallback: CGEventTapCallBack = { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
        if let refcon = refcon, type == .keyDown {
            let listener = Unmanaged<GlobalKeyListener>.fromOpaque(refcon).takeUnretainedValue()
            listener.processKeyEvent(event)
        }
        return Unmanaged.passRetained(event)
    }
}

// Listen to global keyboard events
let globalKeyListener = GlobalKeyListener()
globalKeyListener.startListening()

// Add signal handler for SIGINT
var signalInterrupt = false
let signalHandler: @convention(c) (Int32) -> Void = { _ in
    signalInterrupt = true
    globalKeyListener.stopListening()
    CFRunLoopStop(CFRunLoopGetCurrent())
}
signal(SIGINT, signalHandler)

// Run the main run loop until a signal interrupt occurs
while !signalInterrupt {
    RunLoop.current.run(mode: .default, before: .distantFuture)
}