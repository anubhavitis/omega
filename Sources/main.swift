import Cocoa

class KeyboardMonitor: NSObject {
    private var localMonitor: Any?
    private var globalMonitor: Any?

    func startMonitoring() {
        // Monitor events within our application
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            self.handleKeyEvent(event)
            return event
        }

        // Monitor events globally (in other applications)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { event in
            self.handleKeyEvent(event)
        }
    }

    func stopMonitoring() {
        if let localMonitor = localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }

        if let globalMonitor = globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
    }

    private func getActiveApplication() -> String {
        if let activeApp = NSWorkspace.shared.frontmostApplication {
            return
                "\(activeApp.localizedName) (Bundle ID: \(activeApp.bundleIdentifier ?? "unknown"))"
        }
        return "Unknown Application"
    }

    private func handleKeyEvent(_ event: NSEvent) {
        // Get key information
        let keyCode = event.keyCode
        let characters = event.characters ?? ""
        let modifiers = event.modifierFlags
        let activeApp = getActiveApplication()

        // Print event information
        print("\n--- Keyboard Event ---")
        print("Active Application: \(activeApp)")
        print("Key pressed - Code: \(keyCode), Character: \(characters)")

        // Check for modifier keys (Command, Option, Shift, Control)
        var modifierKeys: [String] = []
        if modifiers.contains(.command) { modifierKeys.append("Command") }
        if modifiers.contains(.option) { modifierKeys.append("Option") }
        if modifiers.contains(.shift) { modifierKeys.append("Shift") }
        if modifiers.contains(.control) { modifierKeys.append("Control") }

        if !modifierKeys.isEmpty {
            print("Modifier keys: \(modifierKeys.joined(separator: " + "))")
        }
        print("-------------------")
    }
}

// Create the application
class AppDelegate: NSObject, NSApplicationDelegate {
    let keyboardMonitor = KeyboardMonitor()

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("Keyboard monitoring started. Press Cmd+C to quit.")
        keyboardMonitor.startMonitoring()
    }

    func applicationWillTerminate(_ notification: Notification) {
        keyboardMonitor.stopMonitoring()
    }
}

// Initialize and run the application
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
