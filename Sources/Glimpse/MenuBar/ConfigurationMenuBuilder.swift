import AppKit

/// Builds the native right-click configuration menu.
///
/// Pure construction kept separate from the controller so the menu's structure
/// is easy to read and adjust.
enum ConfigurationMenuBuilder {
    static func build(
        cameras: [CameraDevice],
        activeCameraID: String?,
        launchAtLogin: Bool,
        target: AnyObject,
        selectCamera: Selector,
        toggleLaunchAtLogin: Selector,
        resetWindow: Selector,
        quit: Selector
    ) -> NSMenu {
        let menu = NSMenu()

        // Camera selection
        let cameraHeader = NSMenuItem(title: "Camera", action: nil, keyEquivalent: "")
        cameraHeader.isEnabled = false
        menu.addItem(cameraHeader)

        if cameras.isEmpty {
            let none = NSMenuItem(title: "No cameras found", action: nil, keyEquivalent: "")
            none.isEnabled = false
            menu.addItem(none)
        } else {
            for device in cameras {
                let item = NSMenuItem(title: device.name, action: selectCamera, keyEquivalent: "")
                item.target = target
                item.representedObject = device.id
                item.state = device.id == activeCameraID ? .on : .off
                menu.addItem(item)
            }
        }

        menu.addItem(.separator())

        // Launch at login
        let login = NSMenuItem(
            title: "Launch at Login",
            action: toggleLaunchAtLogin,
            keyEquivalent: ""
        )
        login.target = target
        login.state = launchAtLogin ? .on : .off
        menu.addItem(login)

        // Reset window
        let reset = NSMenuItem(
            title: "Reset Window Size & Position",
            action: resetWindow,
            keyEquivalent: ""
        )
        reset.target = target
        menu.addItem(reset)

        menu.addItem(.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit Glimpse", action: quit, keyEquivalent: "q")
        quitItem.target = target
        menu.addItem(quitItem)

        return menu
    }
}
