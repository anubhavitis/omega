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

    // Only process if we're in a browser
    let activeApp = kbOperator.getActiveApplication()
    guard kbOperator.isTargetApplication(activeApp.bundleId) else {
        return Unmanaged.passRetained(event)
    }

    // if keyboard event, ie. keyDown or keyUp
    if type == .keyDown || type == .keyUp {
        if let keyName = kbOperator.getKeyName(event: event) {
            let keyType = (type == .keyDown) ? "KeyDown" : "KeyUp"
            print("\(activeApp.name):: \(keyType) :: keyName: \(keyName)")
        }

        // the acutal modification
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)  // Get modifier flags
        //print("the code is \(keyCode)") safario
        if keyCode == 0 {
            event.setIntegerValueField(.keyboardEventKeycode, value: 34)  // changing it to 34
            print(">>>>>>>>>>  Modified Key: Changed 'a' to 'i'")
            return Unmanaged.passRetained(event)
        } else if keyCode == 3 {
            // this is e
            event.setIntegerValueField(.keyboardEventKeycode, value: 2)  // changing it to d
            print(">>>>>>>>>>  Modified Key: Changed 'a' to 'i'")
            return Unmanaged.passRetained(event)

        }
    }

    return Unmanaged.passRetained(event)
}
