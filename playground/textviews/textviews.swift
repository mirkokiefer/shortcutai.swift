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
        var attributedString: AnyObject?
        let rangeValue = NSValue(range: NSRange(location: 0, length: -1))
        let errorAttrString = AXUIElementCopyParameterizedAttributeValue(textViewElement, NSAccessibility.ParameterizedAttribute.attributedStringForRange.rawValue as CFString, rangeValue, &attributedString)
        
        if case .success = errorAttrString, let attrString = attributedString as? NSAttributedString {
            print("Focused text view content with markup: \(attrString.string)")
        } else {
            print("Could not fetch focused text view content with markup.")
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