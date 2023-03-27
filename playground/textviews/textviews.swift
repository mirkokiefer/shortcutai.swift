import Foundation
import AppKit
import CoreGraphics
import ApplicationServices

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

// Request accessibility permissions
requestAccessibilityPermissions()

// Check focused text view content every second
let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
    fetchFocusedTextViewContent()
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