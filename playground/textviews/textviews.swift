import Foundation
import AppKit
import CoreGraphics
import ApplicationServices
import Accessibility

// Function to request accessibility permissions
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

func checkNotesAppPermissions() -> Bool {
    let appleScript = """
    tell application "Notes"
        get version
    end tell
    """

    var error: NSDictionary?
    if let scriptObject = NSAppleScript(source: appleScript) {
        if scriptObject.executeAndReturnError(&error) != nil {
            return true
        } else {
            print("Could not access the Notes app using AppleScript.")
            if let errorDict = error {
                print("Error: \(errorDict)")
            }
        }
    } else {
        print("Failed to create AppleScript object.")
    }

    // Instructions for granting permissions
    print("""
    To grant permissions:
    1. Open System Preferences
    2. Go to Security & Privacy
    3. Click on the Privacy tab
    4. In the sidebar, click on Automation
    5. Find your app in the list and check the box next to Notes
    """)

    return false
}

// Function to fetch the content of the focused text view element
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

func findTextViewInElement(_ element: AXUIElement) -> AXUIElement? {
    var children: CFArray?
    
    let error = withUnsafeMutablePointer(to: &children) { (ptr) -> AXError in
        ptr.withMemoryRebound(to: Optional<CFTypeRef>.self, capacity: 1) {
            AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, $0)
        }
    }
    
    if error == .success, let childrenArray = children as? [AXUIElement] {
        for child in childrenArray {
            var role: AnyObject?
            AXUIElementCopyAttributeValue(child, kAXRoleAttribute as CFString, &role)
            if let roleString = role as? String, (roleString == "AXTextArea" || roleString == "AXTextField") {
                return child
            } else {
                if let textView = findTextViewInElement(child) {
                    return textView
                }
            }
        }
    }
    return nil
}

func fetchFocusedTextViewContentWithMarkup() {
    let frontmostApp = NSWorkspace.shared.frontmostApplication
    guard let app = frontmostApp else {
        print("Failed to fetch the focused application")
        return
    }
    
    let appElement = AXUIElementCreateApplication(app.processIdentifier)
    if let textViewElement = findTextViewInElement(appElement) {
        var textValue: AnyObject?
        let errorText = AXUIElementCopyAttributeValue(textViewElement, kAXValueAttribute as CFString, &textValue)
        
        if case .success = errorText, let text = textValue as? String {
            var range = NSRange(location: 0, length: text.count)
            let rangeValue = AXValueCreate(AXValueType(rawValue: kAXValueCFRangeType)!, &range)
            
            if let unwrappedRangeValue = rangeValue { // Safely unwrap the rangeValue optional
                var attributedString: AnyObject?
                let errorAttrString = AXUIElementCopyParameterizedAttributeValue(textViewElement, kAXAttributedStringForRangeParameterizedAttribute as CFString, unwrappedRangeValue, &attributedString)
                
                if case .success = errorAttrString, let attrString = attributedString as? NSAttributedString {
    let documentAttributes: [NSAttributedString.DocumentAttributeKey: Any] = [
        .documentType: NSAttributedString.DocumentType.html,
        .characterEncoding: String.Encoding.utf8.rawValue
    ]
    if let htmlData = try? attrString.data(from: NSRange(location: 0, length: attrString.length), documentAttributes: documentAttributes),
       let htmlString = String(data: htmlData, encoding: .utf8) {
        print("Focused text view content with markup (HTML): \(htmlString)")
    } else {
        print("Failed to convert attributed string to HTML.")
    }
} else {
    print("Could not fetch focused text view content with markup.")
}
            } else {
                print("Could not create range value.")
            }
        } else {
            print("Could not fetch focused text view content.")
        }
    } else {
        print("Failed to find the text view in the focused application")
    }
}

func fetchFocusedTextViewSelectedContentWithMarkup() {
    let frontmostApp = NSWorkspace.shared.frontmostApplication
    guard let app = frontmostApp else {
        print("Failed to fetch the focused application")
        return
    }
    
    let appElement = AXUIElementCreateApplication(app.processIdentifier)
    var focusedElement: AnyObject?
    let errorElement = AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
    
    if case .success = errorElement, let element = focusedElement, CFGetTypeID(element) == AXUIElementGetTypeID() {
        var selectedText: AnyObject?
        let errorSelectedText = AXUIElementCopyAttributeValue(element as! AXUIElement, kAXSelectedTextAttribute as CFString, &selectedText)
        
        if case .success = errorSelectedText, let text = selectedText as? String {
            print("Focused text view selected text with markup: \(text)")
        } else {
            print("Could not fetch focused text view selected text with markup.")
        }
    } else {
        print("Failed to fetch the focused UI element")
    }
}

// Request accessibility permissions
requestAccessibilityPermissions()
checkNotesAppPermissions()

// Check focused text view content every second
let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
    fetchFocusedTextViewContent()
    fetchFocusedTextViewContentWithMarkup()
    fetchFocusedTextViewSelectedContentWithMarkup()
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