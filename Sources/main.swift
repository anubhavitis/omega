import Cocoa

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
