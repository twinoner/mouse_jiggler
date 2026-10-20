import AppKit
import ApplicationServices
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private let jiggler = Jiggler()

    private let distanceOptions = [1, 2, 5, 10, 20, 50]
    private let intervalOptions = [10, 30, 60, 120, 300, 600]
    private let idleThresholdOptions = [10, 30, 60, 120, 300, 600, 1800]

    func applicationDidFinishLaunching(_ notification: Notification) {
        Settings.registerDefaults()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        // Prompts the user to grant Accessibility access if not yet trusted.
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)

        applyEnabled()
    }

    // MARK: - Menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        if !AXIsProcessTrusted() {
            menu.addItem(makeItem("⚠️ Grant Accessibility Access…", #selector(openAccessibilitySettings)))
            menu.addItem(.separator())
        }

        let enabledItem = makeItem("Enabled", #selector(toggleEnabled))
        enabledItem.state = Settings.enabled ? .on : .off
        menu.addItem(enabledItem)
        menu.addItem(.separator())

        menu.addItem(makeSubmenu("Distance", options: distanceOptions, current: Settings.distance,
                                 format: { "\($0) px" }, action: #selector(setDistance)))
        menu.addItem(makeSubmenu("Interval", options: intervalOptions, current: Settings.interval,
                                 format: formatSeconds, action: #selector(setInterval)))
        menu.addItem(makeSubmenu("Idle Threshold", options: idleThresholdOptions, current: Settings.idleThreshold,
                                 format: formatSeconds, action: #selector(setIdleThreshold)))
        menu.addItem(.separator())

        let loginItem = makeItem("Launch at Login", #selector(toggleLaunchAtLogin))
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(loginItem)
        menu.addItem(.separator())

        menu.addItem(NSMenuItem(title: "Quit Mouse Jiggler", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    private func makeItem(_ title: String, _ action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    private func makeSubmenu(_ title: String, options: [Int], current: Int,
                             format: (Int) -> String, action: Selector) -> NSMenuItem {
        let parent = NSMenuItem(title: "\(title): \(format(current))", action: nil, keyEquivalent: "")
        let submenu = NSMenu()
        for value in options {
            let item = makeItem(format(value), action)
            item.representedObject = value
            item.state = value == current ? .on : .off
            submenu.addItem(item)
        }
        parent.submenu = submenu
        return parent
    }

    private func formatSeconds(_ seconds: Int) -> String {
        seconds < 60 ? "\(seconds) sec" : "\(seconds / 60) min"
    }

    // MARK: - Actions

    @objc private func toggleEnabled() {
        Settings.enabled.toggle()
        applyEnabled()
    }

    @objc private func setDistance(_ sender: NSMenuItem) {
        if let value = sender.representedObject as? Int { Settings.distance = value }
    }

    @objc private func setInterval(_ sender: NSMenuItem) {
        if let value = sender.representedObject as? Int { Settings.interval = value }
    }

    @objc private func setIdleThreshold(_ sender: NSMenuItem) {
        if let value = sender.representedObject as? Int { Settings.idleThreshold = value }
    }

    @objc private func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled {
                try service.unregister()
            } else {
                try service.register()
                if service.status == .requiresApproval { SMAppService.openSystemSettingsLoginItems() }
            }
        } catch {
            let alert = NSAlert(error: error)
            alert.messageText = "Couldn't change Launch at Login"
            alert.runModal()
        }
    }

    @objc private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    // MARK: - State

    private func applyEnabled() {
        if Settings.enabled { jiggler.start() } else { jiggler.stop() }

        guard let button = statusItem.button else { return }
        let symbol = Settings.enabled ? "cursorarrow.motionlines" : "cursorarrow"
        if let image = NSImage(systemSymbolName: symbol, accessibilityDescription: "Mouse Jiggler") {
            image.isTemplate = true
            button.image = image
        } else {
            button.title = "MJ"
        }
        button.appearsDisabled = !Settings.enabled
        button.toolTip = Settings.enabled ? "Mouse Jiggler: on" : "Mouse Jiggler: off"
    }
}
