import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    let keyboardMonitor = KeyboardMonitor()
    var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        keyboardMonitor.startMonitoring()

        // Create the window
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "My App"

        // Create the main view
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))

        // Create first input box
        let inputBox1 = NSTextField(frame: NSRect(x: 20, y: 220, width: 360, height: 24))
        inputBox1.placeholderString = "First Input"
        contentView.addSubview(inputBox1)

        // Create second input box
        let inputBox2 = NSTextField(frame: NSRect(x: 20, y: 180, width: 360, height: 24))
        inputBox2.placeholderString = "Second Input"
        contentView.addSubview(inputBox2)

        // Create application selector popup
        let appSelector = NSPopUpButton(frame: NSRect(x: 20, y: 140, width: 360, height: 24))

        // Get running applications
        let runningApps = NSWorkspace.shared.runningApplications
        runningApps.forEach { app in
            if let appName = app.localizedName {
                let menuItem = NSMenuItem(title: appName, action: nil, keyEquivalent: "")

                // Get the app icon and resize it
                if let appIcon = app.icon {
                    let resizedIcon = NSImage(size: NSSize(width: 16, height: 16))
                    resizedIcon.lockFocus()
                    appIcon.draw(
                        in: NSRect(x: 0, y: 0, width: 16, height: 16),
                        from: NSRect(
                            x: 0, y: 0, width: appIcon.size.width, height: appIcon.size.height),
                        operation: .sourceOver,
                        fraction: 1.0)
                    resizedIcon.unlockFocus()
                    menuItem.image = resizedIcon
                }

                appSelector.menu?.addItem(menuItem)
            }
        }
        contentView.addSubview(appSelector)

        // Create button
        let button = NSButton(frame: NSRect(x: 20, y: 100, width: 360, height: 24))
        button.title = "Submit"
        button.bezelStyle = .rounded
        button.target = self
        button.action = #selector(buttonClicked(_:))
        contentView.addSubview(button)

        // Set the window's content view
        window.contentView = contentView

        // Show the window
        window.makeKeyAndOrderFront(nil)

        // Keep the app running
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func buttonClicked(_ sender: NSButton) {
        // Handle button click
        print("Button clicked")
    }

    func applicationWillTerminate(_ notification: Notification) {
        keyboardMonitor.stopMonitoring()
    }
}

// Initialize and run the application
let app = NSApplication.shared
app.setActivationPolicy(.regular)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
