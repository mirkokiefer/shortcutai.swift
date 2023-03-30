import Foundation
import AppKit

func getActiveTextboxContentInChrome() -> String? {
    let appleScript = """
    tell application "Google Chrome"
        set activeTab to active tab of front window
        set extractedText to execute activeTab javascript "var activeElement = document.activeElement; if (activeElement.tagName === 'INPUT' || activeElement.tagName === 'TEXTAREA' || activeElement.isContentEditable) {activeElement.value || activeElement.innerText;} else {'';}"
    end tell
    """

    var error: NSDictionary?
    if let scriptObject = NSAppleScript(source: appleScript) {
        if let output = scriptObject.executeAndReturnError(&error).stringValue {
            return output
        } else {
            print("Failed to get the active textbox content in Chrome.")
            if let errorDict = error {
                print("Error: \(errorDict)")
            }
        }
    } else {
        print("Failed to create AppleScript object.")
    }

    return nil
}

func getActiveTextboxContentInSafari() -> String? {
    let appleScript = """
    tell application "Safari"
        set extractedText to do JavaScript "var activeElement = document.activeElement; if (activeElement.tagName === 'INPUT' || activeElement.tagName === 'TEXTAREA' || activeElement.isContentEditable) {activeElement.value || activeElement.innerText;} else {'';}" in front document
    end tell
    """

    var error: NSDictionary?
    if let scriptObject = NSAppleScript(source: appleScript) {
        if let output = scriptObject.executeAndReturnError(&error).stringValue {
            return output
        } else {
            print("Failed to get the active textbox content in Safari.")
            if let errorDict = error {
                print("Error: \(errorDict)")
            }
        }
    } else {
        print("Failed to create AppleScript object.")
    }

    return nil
}

func fetchSelectedNoteContentWithMarkupViaAppleScript() {
    let appleScript = """
    tell application "Notes"
        set selectedNote to item 1 of (get selection)
        set noteContent to the body of selectedNote
    end tell
    return noteContent
    """

    var error: NSDictionary?
    if let scriptObject = NSAppleScript(source: appleScript) {
        if let output = scriptObject.executeAndReturnError(&error).stringValue {
            print("Selected note content with markup via AS: \(output)")
        } else {
            print("Failed to fetch the selected note content with markup via AS.")
            if let errorDict = error {
                print("Error: \(errorDict)")
            }
        }
    } else {
        print("Failed to create AppleScript object.")
    }
}

// Check focused text view content every second
let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
    
if let contentInChrome = getActiveTextboxContentInChrome() {
    print("Active textbox content in Chrome: \(contentInChrome)")
}

if let contentInSafari = getActiveTextboxContentInSafari() {
    print("Active textbox content in Safari: \(contentInSafari)")
}

fetchSelectedNoteContentWithMarkupViaAppleScript()

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

