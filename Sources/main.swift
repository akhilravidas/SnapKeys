import AppKit
import ApplicationServices
import Carbon
import Foundation

private let controlOption = UInt32(controlKey | optionKey)
private let controlOptionShift = UInt32(controlKey | optionKey | shiftKey)

private enum WindowAction: Int, CaseIterable {
    case leftFiveEighths
    case rightThreeEighths
    case left
    case right
    case top
    case bottom
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    case leftThird
    case centerThird
    case rightThird
    case leftTwoThirds
    case centerTwoThirds
    case rightTwoThirds
    case maximize
    case center

    var title: String {
        switch self {
        case .leftFiveEighths: return "Left 5/8"
        case .rightThreeEighths: return "Right 3/8"
        case .left: return "Left"
        case .right: return "Right"
        case .top: return "Top"
        case .bottom: return "Bottom"
        case .topLeft: return "Top Left"
        case .topRight: return "Top Right"
        case .bottomLeft: return "Bottom Left"
        case .bottomRight: return "Bottom Right"
        case .leftThird: return "Left Third"
        case .centerThird: return "Center Third"
        case .rightThird: return "Right Third"
        case .leftTwoThirds: return "Left Two Thirds"
        case .centerTwoThirds: return "Center Two Thirds"
        case .rightTwoThirds: return "Right Two Thirds"
        case .maximize: return "Maximize"
        case .center: return "Center"
        }
    }

    var hotKey: HotKey? {
        switch self {
        case .leftFiveEighths: return HotKey(keyCode: UInt32(kVK_ANSI_E), modifiers: controlOption, display: "^⌥E")
        case .rightThreeEighths: return HotKey(keyCode: UInt32(kVK_ANSI_G), modifiers: controlOption, display: "^⌥G")
        case .left: return HotKey(keyCode: UInt32(kVK_LeftArrow), modifiers: controlOption, display: "^⌥←")
        case .right: return HotKey(keyCode: UInt32(kVK_RightArrow), modifiers: controlOption, display: "^⌥→")
        case .top: return HotKey(keyCode: UInt32(kVK_UpArrow), modifiers: controlOption, display: "^⌥↑")
        case .bottom: return HotKey(keyCode: UInt32(kVK_DownArrow), modifiers: controlOption, display: "^⌥↓")
        case .topLeft: return HotKey(keyCode: UInt32(kVK_ANSI_U), modifiers: controlOption, display: "^⌥U")
        case .topRight: return HotKey(keyCode: UInt32(kVK_ANSI_I), modifiers: controlOption, display: "^⌥I")
        case .bottomLeft: return HotKey(keyCode: UInt32(kVK_ANSI_J), modifiers: controlOption, display: "^⌥J")
        case .bottomRight: return HotKey(keyCode: UInt32(kVK_ANSI_K), modifiers: controlOption, display: "^⌥K")
        case .leftThird: return HotKey(keyCode: UInt32(kVK_ANSI_D), modifiers: controlOption, display: "^⌥D")
        case .centerThird: return HotKey(keyCode: UInt32(kVK_ANSI_F), modifiers: controlOption, display: "^⌥F")
        case .rightThird: return HotKey(keyCode: UInt32(kVK_ANSI_H), modifiers: controlOption, display: "^⌥H")
        case .leftTwoThirds: return HotKey(keyCode: UInt32(kVK_ANSI_W), modifiers: controlOptionShift, display: "^⌥⇧W")
        case .centerTwoThirds: return HotKey(keyCode: UInt32(kVK_ANSI_R), modifiers: controlOption, display: "^⌥R")
        case .rightTwoThirds: return HotKey(keyCode: UInt32(kVK_ANSI_T), modifiers: controlOption, display: "^⌥T")
        case .maximize: return HotKey(keyCode: UInt32(kVK_Return), modifiers: controlOption, display: "^⌥↩")
        case .center: return HotKey(keyCode: UInt32(kVK_ANSI_C), modifiers: controlOption, display: "^⌥C")
        }
    }
}

private struct HotKey {
    let keyCode: UInt32
    let modifiers: UInt32
    let display: String
}

private final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var permissionStatusItem: NSMenuItem!
    private var hotKeyRefs: [EventHotKeyRef?] = []
    private var hotKeyActions: [UInt32: WindowAction] = [:]
    private var lastNonSelfApplication: NSRunningApplication?
    private var didPromptForAccessibility = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        rememberFrontmostApplication()
        observeApplicationActivation()
        buildMenu()
        registerHotKeys()
        _ = accessibilityTrusted(prompt: false)
    }

    private func buildMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.title = "⌘"
        statusItem.button?.toolTip = "SnapKeys"

        let menu = NSMenu()
        addActionItems(to: menu, [.leftFiveEighths, .rightThreeEighths])
        menu.addItem(.separator())
        addActionItems(to: menu, [.left, .right, .top, .bottom])
        menu.addItem(.separator())
        addActionItems(to: menu, [.topLeft, .topRight, .bottomLeft, .bottomRight])
        menu.addItem(.separator())
        addActionItems(to: menu, [.leftThird, .centerThird, .rightThird])
        menu.addItem(.separator())
        addActionItems(to: menu, [.leftTwoThirds, .centerTwoThirds, .rightTwoThirds])
        menu.addItem(.separator())
        addActionItems(to: menu, [.maximize, .center])
        menu.addItem(.separator())

        permissionStatusItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        permissionStatusItem.isEnabled = false
        menu.addItem(permissionStatusItem)

        let permissionsItem = NSMenuItem(title: "Grant Accessibility Permission", action: #selector(promptForAccessibility), keyEquivalent: "")
        permissionsItem.target = self
        menu.addItem(permissionsItem)

        let settingsItem = NSMenuItem(title: "Open Accessibility Settings", action: #selector(openAccessibilitySettings), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit SnapKeys", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        menu.delegate = self
        statusItem.menu = menu
        updatePermissionStatus()
    }

    private func addActionItems(to menu: NSMenu, _ actions: [WindowAction]) {
        for action in actions {
            let item = NSMenuItem(title: menuTitle(for: action), action: #selector(runMenuAction(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = action.rawValue
            menu.addItem(item)
        }
    }

    private func menuTitle(for action: WindowAction) -> String {
        guard let hotKey = action.hotKey else { return action.title }
        return "\(action.title)    \(hotKey.display)"
    }

    private func registerHotKeys() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let selfPointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData in
            guard let event, let userData else { return noErr }
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            guard status == noErr else { return status }

            let delegate = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
            delegate.handleHotKey(id: hotKeyID.id)
            return noErr
        }, 1, &eventType, selfPointer, nil)

        for action in WindowAction.allCases {
            guard let hotKey = action.hotKey else { continue }
            let id = UInt32(action.rawValue + 1)
            let hotKeyID = EventHotKeyID(signature: fourCharCode("SnKy"), id: id)
            var ref: EventHotKeyRef?
            let status = RegisterEventHotKey(
                hotKey.keyCode,
                hotKey.modifiers,
                hotKeyID,
                GetApplicationEventTarget(),
                0,
                &ref
            )
            if status == noErr {
                hotKeyRefs.append(ref)
                hotKeyActions[id] = action
            } else {
                NSLog("SnapKeys: failed to register hotkey for \(action.title): \(status)")
            }
        }
    }

    private func handleHotKey(id: UInt32) {
        guard let action = hotKeyActions[id] else { return }
        perform(action)
    }

    @objc private func runMenuAction(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? Int,
              let action = WindowAction(rawValue: rawValue) else { return }
        perform(action)
    }

    private func perform(_ action: WindowAction) {
        guard accessibilityTrusted(prompt: false) else {
            promptForAccessibilityOnce()
            NSSound.beep()
            return
        }
        guard let window = focusedWindow() else {
            NSSound.beep()
            return
        }

        guard let currentFrame = windowFrame(window),
              let screen = screen(containing: currentFrame) else {
            NSSound.beep()
            return
        }

        let target = targetFrame(for: action, in: screen.visibleFrame, current: currentFrame)
        setFrame(target, for: window)
    }

    private func targetFrame(for action: WindowAction, in visibleFrame: CGRect, current: CGRect) -> CGRect {
        let x = visibleFrame.minX
        let y = visibleFrame.minY
        let width = visibleFrame.width
        let height = visibleFrame.height

        switch action {
        case .leftFiveEighths:
            return CGRect(x: x, y: y, width: floor(width * 5.0 / 8.0), height: height)
        case .rightThreeEighths:
            let targetWidth = floor(width * 3.0 / 8.0)
            return CGRect(x: visibleFrame.maxX - targetWidth, y: y, width: targetWidth, height: height)
        case .left:
            return CGRect(x: x, y: y, width: floor(width / 2.0), height: height)
        case .right:
            let targetWidth = floor(width / 2.0)
            return CGRect(x: visibleFrame.maxX - targetWidth, y: y, width: targetWidth, height: height)
        case .top:
            let targetHeight = floor(height / 2.0)
            return CGRect(x: x, y: visibleFrame.maxY - targetHeight, width: width, height: targetHeight)
        case .bottom:
            return CGRect(x: x, y: y, width: width, height: floor(height / 2.0))
        case .topLeft:
            let targetWidth = floor(width / 2.0)
            let targetHeight = floor(height / 2.0)
            return CGRect(x: x, y: visibleFrame.maxY - targetHeight, width: targetWidth, height: targetHeight)
        case .topRight:
            let targetWidth = floor(width / 2.0)
            let targetHeight = floor(height / 2.0)
            return CGRect(x: visibleFrame.maxX - targetWidth, y: visibleFrame.maxY - targetHeight, width: targetWidth, height: targetHeight)
        case .bottomLeft:
            return CGRect(x: x, y: y, width: floor(width / 2.0), height: floor(height / 2.0))
        case .bottomRight:
            let targetWidth = floor(width / 2.0)
            return CGRect(x: visibleFrame.maxX - targetWidth, y: y, width: targetWidth, height: floor(height / 2.0))
        case .leftThird:
            return CGRect(x: x, y: y, width: floor(width / 3.0), height: height)
        case .centerThird:
            let targetWidth = floor(width / 3.0)
            return CGRect(x: x + targetWidth, y: y, width: targetWidth, height: height)
        case .rightThird:
            let targetWidth = floor(width / 3.0)
            return CGRect(x: visibleFrame.maxX - targetWidth, y: y, width: targetWidth, height: height)
        case .leftTwoThirds:
            return CGRect(x: x, y: y, width: floor(width * 2.0 / 3.0), height: height)
        case .centerTwoThirds:
            let targetWidth = floor(width * 2.0 / 3.0)
            return CGRect(x: x + floor((width - targetWidth) / 2.0), y: y, width: targetWidth, height: height)
        case .rightTwoThirds:
            let targetWidth = floor(width * 2.0 / 3.0)
            return CGRect(x: visibleFrame.maxX - targetWidth, y: y, width: targetWidth, height: height)
        case .maximize:
            return visibleFrame
        case .center:
            let targetWidth = min(current.width, width)
            let targetHeight = min(current.height, height)
            return CGRect(
                x: x + floor((width - targetWidth) / 2.0),
                y: y + floor((height - targetHeight) / 2.0),
                width: targetWidth,
                height: targetHeight
            )
        }
    }

    private func focusedWindow() -> AXUIElement? {
        let systemWide = AXUIElementCreateSystemWide()
        if let window = copyAXElement(systemWide, kAXFocusedWindowAttribute) {
            return window
        }

        let app = NSWorkspace.shared.frontmostApplication.flatMap { isSelf($0) ? lastNonSelfApplication : $0 } ?? lastNonSelfApplication
        guard let pid = app?.processIdentifier else { return nil }
        let axApp = AXUIElementCreateApplication(pid)

        if let window = copyAXElement(axApp, kAXFocusedWindowAttribute) {
            return window
        }

        if let windows = copyAXAny(axApp, kAXWindowsAttribute) as? [AXUIElement] {
            return windows.first
        }

        return nil
    }

    private func copyAXElement(_ element: AXUIElement, _ attribute: String) -> AXUIElement? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard result == .success else { return nil }
        return (value as! AXUIElement)
    }

    private func copyAXAny(_ element: AXUIElement, _ attribute: String) -> Any? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard result == .success else { return nil }
        return value
    }

    private func windowFrame(_ window: AXUIElement) -> CGRect? {
        guard let positionValue = copyRawAXAttribute(window, kAXPositionAttribute),
              let sizeValue = copyRawAXAttribute(window, kAXSizeAttribute) else { return nil }

        var position = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(positionValue, .cgPoint, &position),
              AXValueGetValue(sizeValue, .cgSize, &size) else { return nil }

        return appKitRect(fromAXPosition: position, size: size)
    }

    private func copyRawAXAttribute(_ element: AXUIElement, _ attribute: String) -> AXValue? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard result == .success else { return nil }
        return (value as! AXValue)
    }

    private func setFrame(_ frame: CGRect, for window: AXUIElement) {
        var size = frame.size
        var position = axPosition(fromAppKitRect: frame)
        guard let sizeValue = AXValueCreate(.cgSize, &size),
              let positionValue = AXValueCreate(.cgPoint, &position) else { return }

        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
    }

    private func screen(containing frame: CGRect) -> NSScreen? {
        let center = CGPoint(x: frame.midX, y: frame.midY)
        return NSScreen.screens.first(where: { $0.frame.contains(center) }) ?? NSScreen.main
    }

    private func appKitRect(fromAXPosition position: CGPoint, size: CGSize) -> CGRect {
        let maxY = globalScreenMaxY()
        return CGRect(x: position.x, y: maxY - position.y - size.height, width: size.width, height: size.height)
    }

    private func axPosition(fromAppKitRect rect: CGRect) -> CGPoint {
        let maxY = globalScreenMaxY()
        return CGPoint(x: rect.minX, y: maxY - rect.maxY)
    }

    private func globalScreenMaxY() -> CGFloat {
        NSScreen.screens.map(\.frame.maxY).max() ?? 0
    }

    private func accessibilityTrusted(prompt: Bool) -> Bool {
        if prompt {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            return AXIsProcessTrustedWithOptions(options)
        }
        return AXIsProcessTrusted()
    }

    private func observeApplicationActivation() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  !self.isSelf(app) else { return }
            self.lastNonSelfApplication = app
        }
    }

    private func rememberFrontmostApplication() {
        guard let app = NSWorkspace.shared.frontmostApplication, !isSelf(app) else { return }
        lastNonSelfApplication = app
    }

    private func isSelf(_ app: NSRunningApplication) -> Bool {
        app.bundleIdentifier == Bundle.main.bundleIdentifier || app.processIdentifier == ProcessInfo.processInfo.processIdentifier
    }

    @objc private func promptForAccessibility() {
        didPromptForAccessibility = true
        if !accessibilityTrusted(prompt: true) {
            openAccessibilitySettings()
        }
    }

    private func promptForAccessibilityOnce() {
        guard !didPromptForAccessibility else { return }
        promptForAccessibility()
    }

    private func updatePermissionStatus() {
        guard let permissionStatusItem else { return }
        if accessibilityTrusted(prompt: false) {
            permissionStatusItem.title = "Accessibility: Granted"
            statusItem.button?.title = "⌘"
        } else {
            permissionStatusItem.title = "Accessibility: Missing"
            statusItem.button?.title = "!"
        }
    }

    @objc private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        updatePermissionStatus()
    }
}

private func fourCharCode(_ string: String) -> OSType {
    var result: UInt32 = 0
    for scalar in string.unicodeScalars.prefix(4) {
        result = (result << 8) + UInt32(scalar.value)
    }
    return result
}

private let app = NSApplication.shared
private let delegate = AppDelegate()
app.delegate = delegate
app.run()
