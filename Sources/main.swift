import Cocoa

class KeyboardMonitor: NSObject {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    func startMonitoring() {
        // Create event tap for both keyDown and keyUp events
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)

        guard
            let eventTap = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: .defaultTap,
                eventsOfInterest: CGEventMask(eventMask),
                callback: eventCallback,
                userInfo: UnsafeMutableRawPointer(Unmanaged.passRetained(self).toOpaque())
            )
        else {
            print("Failed to create event tap")
            return
        }

        self.eventTap = eventTap

        // Create a RunLoop source and add it to the current RunLoop
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)

        // Enable the event tap
        CGEvent.tapEnable(tap: eventTap, enable: true)

        print("Keyboard monitoring started. Press Cmd+C to quit.")
        print("'e' will be changed to 'f' in browsers.")
    }

    func stopMonitoring() {
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            self.runLoopSource = nil
        }

        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            self.eventTap = nil
        }
    }

    public func getActiveApplication() -> (name: String, bundleId: String) {
        if let activeApp = NSWorkspace.shared.frontmostApplication {
            return (
                name: activeApp.localizedName ?? "Unknown",
                bundleId: activeApp.bundleIdentifier ?? "unknown"
            )
        }
        return ("Unknown Application", "unknown")
    }

    public func isBrowser(_ bundleId: String) -> Bool {
        let browserBundleIds = [
            "com.apple.Safari",
            "com.google.Chrome",
            "org.mozilla.firefox",
            "com.microsoft.edgemac",
            "com.brave.Browser",
        ]
        return browserBundleIds.contains(bundleId)
    }
}

private func eventCallback(
    proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon = refcon else {
        return Unmanaged.passRetained(event)
    }

    let keyboardMonitor: KeyboardMonitor = Unmanaged<KeyboardMonitor>.fromOpaque(refcon)
        .takeUnretainedValue()
    let activeApp = keyboardMonitor.getActiveApplication()

    // Only process if we're in a browser
    guard keyboardMonitor.isBrowser(activeApp.bundleId) else {
        return Unmanaged.passRetained(event)
    }

    if type == .keyDown || type == .keyUp {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        // Convert CGEvent to NSEvent to get character
        if let nsEvent = NSEvent(cgEvent: event) {
            let keyChar = nsEvent.characters ?? ""

            print("\n--- Keyboard Event ---")
            print("Active Application: \(activeApp.name) (Bundle ID: \(activeApp.bundleId))")
            print("Event Type: \(type == .keyDown ? "KeyDown" : "KeyUp")")
            print("Original Key: Code: \(keyCode), Character: \(keyChar)")

            // Check if the key is 'e' (keycode 14)
            if keyCode == 14 {
                // Modify to 'f' (keycode 3)
                event.setIntegerValueField(.keyboardEventKeycode, value: 3)

                print("Modified Key: Changed 'e' to 'f'")
                print("-------------------")
                return Unmanaged.passRetained(event)
            }
        }
    }

    return Unmanaged.passRetained(event)
}

// Create the application
class AppDelegate: NSObject, NSApplicationDelegate {
    let keyboardMonitor = KeyboardMonitor()

    func applicationDidFinishLaunching(_ notification: Notification) {
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
