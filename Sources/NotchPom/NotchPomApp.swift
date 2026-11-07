import AppKit
import SwiftUI
import Combine

@main
struct NotchPomApp {
    @MainActor static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        withExtendedLifetime(delegate) { app.run() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model = TimerModel()
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private var panel: NSPanel!
    private var preferences: AnyCancellable?
    private var lastTitle = ""

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePopover)
        statusItem.button?.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: TimerView(model: model))
        panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 108, height: 25),
                        styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.contentView = NSHostingView(rootView: NotchView(model: model))
        model.onChange = { [weak self] in self?.updateStatus() }
        preferences = model.$showNotch.dropFirst().sink { [weak self] visible in
            self?.positionPanel(visible: visible)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(woke),
            name: NSWorkspace.didWakeNotification, object: nil)
        updateStatus()
        positionPanel(visible: model.showNotch)
        if ProcessInfo.processInfo.arguments.contains("--smoke-test") {
            togglePopover()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [self] in
                let checks = statusItem.button != nil && popover.isShown && panel.contentView != nil
                print(checks ? "UI_SMOKE_PASS: status item, popover, notch panel initialized" : "UI_SMOKE_FAIL")
                if let view = popover.contentViewController?.view,
                   let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) {
                    view.cacheDisplay(in: view.bounds, to: bitmap)
                    if let path = ProcessInfo.processInfo.environment["NOTCHPOM_PREVIEW"],
                       let data = bitmap.representation(using: .png, properties: [:]) {
                        try? data.write(to: URL(fileURLWithPath: path))
                    }
                }
                NSApplication.shared.terminate(nil)
            }
        } else if !UserDefaults.standard.bool(forKey: "hasLaunched") {
            UserDefaults.standard.set(true, forKey: "hasLaunched")
            togglePopover()
        }
    }

    @objc private func woke() { model.refresh() }
    @objc private func screensChanged() { positionPanel(visible: model.showNotch) }

    private func updateStatus() {
        let title = "\(model.session.phase == .work ? "◉" : "◌") \(model.time)"
        if title != lastTitle { statusItem.button?.title = title; lastTitle = title }
        statusItem.button?.toolTip = "NotchPom · \(model.label) · \(model.session.isRunning ? "Running" : "Paused")"
    }

    private func positionPanel(visible: Bool) {
        guard visible else { panel.orderOut(nil); return }
        // Prefer the built-in notched display. NSScreen reports actual notch geometry.
        guard let screen = NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }) ?? NSScreen.screens.first else { return }
        let origin: NSPoint
        if let right = screen.auxiliaryTopRightArea, screen.safeAreaInsets.top > 0 {
            origin = NSPoint(x: right.minX + 8, y: right.midY - 12.5)
        } else {
            // On displays without a notch, sit just below the center of the menu bar.
            origin = NSPoint(x: screen.frame.midX - 54, y: screen.visibleFrame.maxY - 33)
        }
        panel.setFrameOrigin(origin)
        panel.orderFrontRegardless()
    }

    @objc private func togglePopover() {
        if popover.isShown { popover.performClose(nil) }
        else if let button = statusItem.button {
            NSApplication.shared.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
