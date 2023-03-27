# Focused Text View Content Fetcher

This Swift script fetches the content of a focused text view on macOS by utilizing the Accessibility APIs. It runs in the background and prints the focused text view content to the console every second.

## Prerequisites

- macOS 10.14 or later
- Swift 5 or later

## Instructions

1. Ensure that you have the required accessibility permissions for the terminal or the app you'll be running the script in. You can use the `requestAccessibilityPermissions()` function in the script to prompt the user to grant the necessary permissions.

2. Save the script as a Swift file, e.g., `fetch.swift`.

3. Open Terminal and navigate to the directory containing the Swift file.

4. Compile the script using the following command:

   ```
   swiftc -o shrtct_fetch fetch.swift
   ```

   This command will compile the script and create an executable file named `shrtct_fetch` in the same directory.

5. Run the compiled script with the following command:

   ```
   ./shrtct_fetch
   ```

   The script will start running and print the focused text view content every second. To stop the script, press `Ctrl+C` in the Terminal.

## Notes

- The script uses the `AXUIElement` API from the Application Services framework to interact with the UI elements on macOS.
- The timer has a 1-second interval for fetching the content, but you can adjust the interval as needed by modifying the `withTimeInterval` parameter in the `Timer.scheduledTimer` function.
```
