import Foundation
import AppKit
import CoreGraphics
import ApplicationServices

func requestAccessibilityPermissions() {
    let trusted = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
    let options = [trusted: true] as CFDictionary
    let accessEnabled = AXIsProcessTrustedWithOptions(options)
    
    if accessEnabled {
        print("Accessibility permissions granted.")
    } else {
        print("To grant accessibility permissions, please follow these steps:")
        print("1. Open System Preferences.")
        print("2. Navigate to Security & Privacy.")
        print("3. Click on the Privacy tab.")
        print("4. Select Accessibility from the list on the left.")
        print("5. Click the lock icon in the lower-left corner to make changes.")
        print("6. Check the box next to your app or terminal to grant access.")
        print("7. Restart the app or terminal for the changes to take effect.")
    }
}

func requestInputMonitoringPermissions() {
    print("""
    ##################################################
    This script requires Input Monitoring permissions.
    ##################################################

    To grant permissions, follow these steps:

    1. Open System Preferences.
    2. Go to Security & Privacy.
    3. Click the Privacy tab.
    4. Scroll down and click on Input Monitoring.
    5. Click the lock icon in the bottom-left corner to unlock the settings (if necessary).
    6. Click the "+" button below the app list and add your Terminal app or the app you're running the script in.
    7. Check the box next to the app to enable Input Monitoring.

    After granting permissions, restart the script.
    """)
}

func fetchFocusedTextViewContent() {
    let frontmostApp = NSWorkspace.shared.frontmostApplication
    guard let app = frontmostApp else {
        print("Failed to fetch the focused application")
        return
    }
    
    let appElement = AXUIElementCreateApplication(app.processIdentifier)
    var focusedElement: AnyObject?
    let errorElement = AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
    
    if case .success = errorElement, let element = focusedElement, CFGetTypeID(element) == AXUIElementGetTypeID() {
        var textValue: AnyObject?
        let errorText = AXUIElementCopyAttributeValue(element as! AXUIElement, kAXValueAttribute as CFString, &textValue)
        
        if case .success = errorText, let text = textValue as? String {
            print("Focused text view content: \(text)")
        } else {
            print("Could not fetch focused text view content.")
        }
    } else {
        print("Failed to fetch the focused UI element")
    }
}

class GlobalKeyListener {
    private var lastThreeCharacters: String = ""
    private var eventTap: CFMachPort?

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

    func stopListening() {
        if let eventTap = eventTap {
            CFMachPortInvalidate(eventTap)
            self.eventTap = nil
        }
    }

    private func processKeyEvent(_ event: CGEvent) {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        if let key = Key(rawValue: CGKeyCode(keyCode)) {
            let character = key.description
            print("Character typed: \(character)")

            lastThreeCharacters.append(character)
            if lastThreeCharacters.count > 3 {
                lastThreeCharacters.removeFirst()
            }

            if lastThreeCharacters == "---" {
                print("--- sequence detected")
                // Add your desired action here
            }
        }
    }

    private let eventTapCallback: CGEventTapCallBack = { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
        if let refcon = refcon, type == .keyDown {
            let listener = Unmanaged<GlobalKeyListener>.fromOpaque(refcon).takeUnretainedValue()
            listener.processKeyEvent(event)
        }
        return Unmanaged.passRetained(event)
    }
}

// Helper enum for key codes
enum Key: CGKeyCode {
    case a = 0x00
    case s = 0x01
    case d = 0x02
    case f = 0x03
    case h = 0x04
    case g = 0x05
    case z = 0x06
    case x = 0x07
    case c = 0x08
    case v = 0x09
    case b = 0x0B
    case q = 0x0C
    case w = 0x0D
    case e = 0x0E
    case r = 0x0F
    case y = 0x10
    case t = 0x11
    case one = 0x12
    case two = 0x13
    case three = 0x14
    case four = 0x15
    case six = 0x16
    case five = 0x17
    case equal = 0x18
    case nine = 0x19
    case seven = 0x1A
    case minus = 0x1B
    case eight = 0x1C
    case zero = 0x1D
    case rightBracket = 0x1E
    case o = 0x1F
    case u = 0x20
    case leftBracket = 0x21
    case i = 0x22
    case p = 0x23
    case l = 0x25
    case j = 0x26
    case quote = 0x27
    case k = 0x28
    case semicolon = 0x29
    case backslash = 0x2A
    case comma = 0x2B
    case slash = 0x2C
    case n = 0x2D
    case m = 0x2E
    case period = 0x2F
    case grave = 0x32
    case keypadDecimal = 0x41
    case keypadMultiply = 0x43
    case keypadPlus = 0x45
    case keypadClear = 0x47
    case keypadDivide = 0x4B
    case keypadEnter = 0x4C
    case keypadMinus = 0x4E
    case keypadEquals = 0x51
    case keypad0 = 0x52
    case keypad1 = 0x53
    case keypad2 = 0x54
    case keypad3 = 0x55
    case keypad4 = 0x56
    case keypad5 = 0x57
    case keypad6 = 0x58
    case keypad7 = 0x59
    case keypad8 = 0x5B
    case keypad9 = 0x5C
}

extension Key: CustomStringConvertible {
    var description: String {
        switch self {
        case .a: return "a"
        case .s: return "s"
        case .d: return "d"
        case .f: return "f"
        case .h: return "h"
        case .g: return "g"
        case .z: return "z"
        case .x: return "x"
        case .c: return "c"
        case .v: return "v"
        case .b: return "b"
        case .q: return "q"
        case .w: return "w"
        case .e: return "e"
        case .r: return "r"
        case .y: return "y"
        case .t: return "t"
        case .one: return "1"
        case .two: return "2"
        case .three: return "3"
        case .four: return "4"
        case .six: return "6"
        case .five: return "5"
        case .equal: return "="
        case .nine: return "9"
        case .seven: return "7"
        case .minus: return "-"
        case .eight: return "8"
        case .zero: return "0"
        case .rightBracket: return "]"
        case .o: return "o"
        case .u: return "u"
        case .leftBracket: return "["
        case .i: return "i"
        case .p: return "p"
        case .l: return "l"
        case .j: return "j"
        case .quote: return "'"
        case .k: return "k"
        case .semicolon: return ";"
        case .backslash: return "\\"
        case .comma: return ","
        case .slash: return "/"
        case .n: return "n"
        case .m: return "m"
        case .period: return "."
        case .grave: return "`"
        case .keypadDecimal: return "."
        case .keypadMultiply: return "*"
        case .keypadPlus: return "+"
        case .keypadClear: return "Clear"
        case .keypadDivide: return "/"
        case .keypadEnter: return "Enter"
        case .keypadMinus: return "-"
        case .keypadEquals: return "="
        case .keypad0: return "0"
        case .keypad1: return "1"
        case .keypad2: return "2"
        case .keypad3: return "3"
        case .keypad4: return "4"
        case .keypad5: return "5"
        case .keypad6: return "6"
        case .keypad7: return "7"
        case .keypad8: return "8"
        case .keypad9: return "9"
        }
    }
}

requestInputMonitoringPermissions()
requestAccessibilityPermissions()

let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
    fetchFocusedTextViewContent()
}

let globalKeyListener = GlobalKeyListener()
globalKeyListener.startListening()

RunLoop.main.run()