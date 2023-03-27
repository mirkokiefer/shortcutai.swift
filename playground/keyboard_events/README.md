# Monitoring Keystrokes on macOS

This script allows you to monitor keystrokes on your macOS system. It listens to keyboard events globally, meaning that it can capture keystrokes from all applications, including those that are running in the background.

## Running the Script

To run the script, follow these steps:

1. Open Terminal on your Mac.
2. Navigate to the directory where the "keyboard_events.swift" file is located.
3. Type "swift keyboard_events.swift" and press Enter.

The script will start running and will display any keystrokes that are made on the system.

## Understanding the Code

The code uses the Core Graphics and ApplicationServices frameworks to capture keystrokes. It creates a global event tap, which is a mechanism for capturing input events at a low level. The script then listens for key events and processes them by extracting the Unicode string associated with the key and any modifier keys that were pressed.

The output of the script is simply printed to the console, but you could modify the code to do something else with the keystroke data.

## Stopping the Script

To stop the script, simply press Ctrl-C in the Terminal window. This will send a SIGINT signal to the script, which will be caught by the signal handler and cause the script to stop running.