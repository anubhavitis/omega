import Cocoa

class KeyboardMonitor: NSObject {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    func startMonitoring() {
        // Create event tap for both keyDown and keyUp events
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)

        guard
            let eventTap = CGEvent.tapCreate(
                // tap: Defines the scope of event monitoring
                // .cgSessionEventTap: Monitor events for current user session
                tap: .cgSessionEventTap,
                // place: Defines where in the event chain to insert our tap
                // .headInsertEventTap: Insert at the beginning of the chain (can modify events before apps receive them)
                place: .headInsertEventTap,
                // options: Defines the behavior of the event tap
                // .defaultTap: Standard behavior (both listen and modify events)
                options: .defaultTap,
                eventsOfInterest: CGEventMask(eventMask),
                callback: eventCallback,

                //  we're bridging Swift and C APIs here, we need to pass a reference to self as the userInfo parameter
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

}

private func eventCallback(
    proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    let kbOperator = keyboardOperator()
    let activeApp = kbOperator.getActiveApplication()

    // Only process if we're in a browser
    guard kbOperator.isTargetApplication(activeApp.bundleId) else {
        return Unmanaged.passRetained(event)
    }

    if type == .keyDown || type == .keyUp {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags  // Get modifier flags

        // Convert CGEvent to NSEvent to get character
        if let nsEvent = NSEvent(cgEvent: event) {
            let keyChar = nsEvent.characters ?? ""

            // Get special key name if applicable
            let specialKeyName = kbOperator.getSpecialKeyName(keyCode: keyCode) ?? keyChar

            // Create array of active modifier keys
            var activeModifiers: [String] = []
            if flags.contains(.maskCommand) { activeModifiers.append("⌘") }
            if flags.contains(.maskAlternate) { activeModifiers.append("⌥") }
            if flags.contains(.maskControl) { activeModifiers.append("⌃") }
            if flags.contains(.maskShift) { activeModifiers.append("⇧") }

            // Build the key combination string
            let keyCombo =
                activeModifiers.isEmpty
                ? specialKeyName
                : "\(activeModifiers.joined(separator: " + "))+\(specialKeyName)"

            print(
                "\(activeApp.name):: \(activeApp.bundleId) :: \(type == .keyDown ? "KeyDown" : "KeyUp") ::\(keyCode) - \(keyChar)"
            )
            if !activeModifiers.isEmpty {
                print("Key Combination: \(keyCombo)")
                print("================")
            }

            // Check if the key is 'e' (keycode 14)
            if keyCode == 15 {
                // Modify to 'f' (keycode 3)
                event.setIntegerValueField(.keyboardEventKeycode, value: 13)
                print(">>>>>>>>>>  Modified Key: Changed 'e' to 'f'")
                return Unmanaged.passRetained(event)
            }
        }
    }

    return Unmanaged.passRetained(event)
}
