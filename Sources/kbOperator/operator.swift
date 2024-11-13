import Cocoa

public class keyboardOperator {
    public func getActiveApplication() -> (name: String, bundleId: String) {
        // First try to get the frontmost application
        if let activeApp = NSWorkspace.shared.frontmostApplication {
            return (
                name: activeApp.localizedName ?? "Unknown",
                bundleId: activeApp.bundleIdentifier ?? "unknown"
            )
        }

        // If frontmost application is not available, try to get the application under mouse
        if let appUnderMouse = NSWorkspace.shared.menuBarOwningApplication {
            return (
                name: appUnderMouse.localizedName ?? "Unknown",
                bundleId: appUnderMouse.bundleIdentifier ?? "unknown"
            )
        }

        // For Spotlight and other system services
        let runningApps = NSWorkspace.shared.runningApplications
        for app in runningApps {
            if app.isActive {
                return (
                    name: app.localizedName ?? "Unknown",
                    bundleId: app.bundleIdentifier ?? "unknown"
                )
            }
        }

        return ("System Service", "com.apple.systemservice")
    }

    public func isTargetApplication(_ bundleId: String) -> Bool {
        let browserBundleIds = [
            "com.apple.Safari",
            "com.google.Chrome",
            "org.mozilla.firefox",
            "com.brave.Browser",
            "com.apple.finder",
        ]
        return browserBundleIds.contains(bundleId)
    }

    func getSpecialKeyName(keyCode: Int64) -> String? {
        let specialKeys: [Int64: String] = [
            51: "⌫ Delete",  // Backspace/Delete
            36: "↩ Return",  // Return
            48: "⇥ Tab",  // Tab
            49: "Space",  // Space
            53: "⎋ Escape",  // Escape
            123: "←",  // Left Arrow
            124: "→",  // Right Arrow
            125: "↓",  // Down Arrow
            126: "↑",  // Up Arrow
            116: "Page Up",  // Page Up
            121: "Page Down",  // Page Down
            115: "Home",  // Home
            119: "End",  // End
            117: "⌦ Delete",  // Forward Delete
            122: "F1",  // F1
            120: "F2",  // F2
            99: "F3",  // F3
            118: "F4",  // F4
            96: "F5",  // F5
            97: "F6",  // F6
            98: "F7",  // F7
            100: "F8",  // F8
            101: "F9",  // F9
            109: "F10",  // F10
            103: "F11",  // F11
            111: "F12",  // F12
        ]
        return specialKeys[keyCode]
    }

    //  TODO: write evenTransformer function here
}
