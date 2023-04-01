# ShortcutAI for Swift

ShortcutAI is a Swift package that provides a set of utilities for building keyboard shortcut automation features.

## Features

- Requesting accessibility permissions
- Requesting input monitoring permissions
- Fetching the content of the currently focused text view
- Listening for global key events
- Performing custom actions when specific key sequences are detected
- Detecting custom key sequences
- Handle streaming responses from the ShortcutAI API

## Usage

To use ShortcutAI in your project, simply add it as a dependency in your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/ShortcutAI.git", from: "1.0.0")
]
```

Then import the module in your source files:

```swift
import ShortcutAI
```

### Requesting Accessibility Permissions

To request accessibility permissions in your app, use the `requestAccessibilityPermissions()` function:

```swift
import ShortcutAI

requestAccessibilityPermissions()
```

### Requesting Input Monitoring Permissions

To request input monitoring permissions in your app, use the `requestInputMonitoringPermissions()` function:

```swift
import ShortcutAI

requestInputMonitoringPermissions()
```

### Fetching Focused Text View Content

To fetch the content of the currently focused text view in your app, use the `fetchFocusedTextViewContent()` function:

```swift
import ShortcutAI

fetchFocusedTextViewContent()
```

### Listening for Global Key Events

To listen for global key events in your app, use the `GlobalKeyListener` class:

```swift
import ShortcutAI

let listener = GlobalKeyListener()
listener.startListening()

// Later, when you want to stop listening:
listener.stopListening()
```

### Detecting Custom Key Sequences

To perform custom actions when specific key sequences are detected in your app, you can create your own `KeySequenceHandler` and pass it to the `GlobalKeyListener`:

```swift
import ShortcutAI

class MyKeySequenceHandler: KeySequenceHandler {
    func handleKeySequence() {
        // Implement your custom logic here
    }
}

let listener = GlobalKeyListener()
listener.setKeySequences(["abc", "123"]) // Configurable key sequences
listener.setKeySequenceHandler(MyKeySequenceHandler())
listener.startListening()

// Later, when you want to stop listening:
listener.stopListening()
```

Note that the `setKeySequences(_ keySequences: [String])` method allows you to set the key sequences to listen for, and the `KeySequenceHandler` protocol defines the `handleKeySequence()` method that you can implement with your custom logic.

## License

ShortcutAI is available under the MIT license. See the LICENSE file for more info.