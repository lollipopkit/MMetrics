import AppKit
import SwiftUI
import Combine
import ServiceManagement
import WidgetKit

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate, NSWindowDelegate {

    var statusItem: NSStatusItem?
    var popover    = NSPopover()
    var welcomeWin: NSWindow?
    var settingsWin: NSWindow?
    let model      = SystemStatsModel()

    // Anchor tracking for the popover — see beginTrackingAnchor(_:).
    private var anchorObservers: [NSObjectProtocol] = []
    private var anchorOrigin: NSPoint?
    private var outsideClickMonitor: Any?
    private var lastWidgetReload = Date.distantPast

    // Subscribe to model changes so the label updates in sync with each tick,
    // not on a separate independent timer that may fire before data is ready.
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        UserDefaults.standard.register(defaults: [
            "appTheme": AppTheme.automatic.rawValue
        ].merging(DashboardSection.registrationDefaults) { $1 }
         .merging(MenuBarItem.registrationDefaults) { $1 })

        setupMenuBar()
        model.startMonitoring()

        // Redraw the label once per batch of model updates. objectWillChange fires
        // before each property is set, so debounce until the tick's writes land.
        model.objectWillChange
            .debounce(for: .milliseconds(50), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateLabel()
                self?.refreshWidgetsIfDue()
            }
            .store(in: &cancellables)

        // Menu bar item selection changed in Settings.
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateLabel() }
            .store(in: &cancellables)

        // Restore Open at Login state on launch
        if UserDefaults.standard.bool(forKey: "openAtLogin") {
            try? SMAppService.mainApp.register()
        }

        // Show welcome window on very first launch
        if !UserDefaults.standard.bool(forKey: "hasLaunched") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.showWelcomeWindow()
            }
        }

        // Check for updates in the background — non-blocking
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 5.0) {
            UpdateChecker.shared.check()
        }
    }

    // MARK: - Menu bar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let btn = statusItem?.button {
            btn.imagePosition = .imageOnly
            btn.toolTip = "MMetrics"
            updateLabel()
            btn.target = self
            btn.action = #selector(handleClick)
            btn.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        popover.contentSize = NSSize(width: 340, height: 640)
        popover.behavior    = .transient
        popover.animates    = true
        popover.delegate    = self
        popover.contentViewController = NSHostingController(
            rootView: PopoverView(model: model)
        )
    }

    private func updateLabel() {
        guard let btn = statusItem?.button else { return }
        let items = MenuBarItem.enabledItems
        // Settings keep at least one item checked; fall back to CPU so the item stays clickable.
        let cells = (items.isEmpty ? [.cpu] : items).map(menuBarCell)
        btn.image = MenuBarLabel.image(for: cells)
        btn.setAccessibilityLabel(cells.map { "\($0.label) \($0.value)" }.joined(separator: ", "))
    }

    private func menuBarCell(_ item: MenuBarItem) -> MenuBarLabel.Cell {
        let value: String, widest: String
        switch item {
        case .cpu:         (value, widest) = ("\(model.cpuUsage)%", "99%")
        case .memory:      (value, widest) = ("\(model.memPct)%", "99%")
        case .gpu:         (value, widest) = ("\(model.gpuUsage)%", "99%")
        case .temperature:
            value  = model.cpuTemp > 0 ? String(format: "%.0f°C", model.cpuTemp) : "--"
            widest = "99°C"
        case .power:
            value  = model.sysPower > 0 ? String(format: "%.0fW", model.sysPower) : "--"
            widest = "99W"
        case .netDown:     (value, widest) = (Self.compactRate(model.netInBps), "999K")
        case .netUp:       (value, widest) = (Self.compactRate(model.netOutBps), "999K")
        }
        return MenuBarLabel.Cell(value: value, label: item.caption, widest: widest)
    }

    /// Bytes per second in at most four characters, e.g. "0K", "512K", "1.2M", "34M".
    private static func compactRate(_ bps: Int64) -> String {
        let kb = Double(bps) / 1024
        if kb < 999.5 { return String(format: "%.0fK", kb) }
        let mb = kb / 1024
        if mb < 9.95 { return String(format: "%.1fM", mb) }
        if mb < 999.5 { return String(format: "%.0fM", mb) }
        return String(format: "%.1fG", mb / 1024)
    }

    // MARK: - Click handling

    @objc func handleClick(_ sender: NSStatusBarButton) {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover(sender)
        }
    }

    func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
            beginTrackingAnchor(sender)
        }
    }

    // MARK: - Anchor tracking

    /// The popover is positioned relative to the status item button. In native
    /// full-screen mode the menu bar auto-hides, which slides the button's window
    /// off the top of the screen. AppKit keeps the popover attached to that anchor,
    /// so it flashes and lands in the top-right corner with its top edge clipped.
    ///
    /// Rather than fight AppKit's positioning, dismiss the popover as soon as the
    /// anchor stops being a valid thing to point at.
    private func beginTrackingAnchor(_ button: NSStatusBarButton) {
        endTrackingAnchor()

        guard let anchorWindow = button.window else { return }
        anchorOrigin = anchorWindow.frame.origin

        let center = NotificationCenter.default

        // The menu bar retracting moves the status item's window.
        anchorObservers.append(
            center.addObserver(forName: NSWindow.didMoveNotification,
                               object: anchorWindow,
                               queue: .main) { [weak self] _ in
                self?.closeIfAnchorInvalid(anchorWindow)
            }
        )

        // Display or Space changes can also relocate the anchor.
        anchorObservers.append(
            center.addObserver(forName: NSApplication.didChangeScreenParametersNotification,
                               object: nil,
                               queue: .main) { [weak self] _ in
                self?.closeIfAnchorInvalid(anchorWindow)
            }
        )

        // Collapse when the user clicks anything outside the dashboard, the same way
        // clicking the menu bar icon again collapses it.
        //
        // NSPopover.behavior = .transient is supposed to do this, but the app runs as
        // .accessory: a click in another application is delivered to that application
        // and never reaches us, so the popover just sits there. A global monitor sees
        // those events. It deliberately does not fire for clicks inside our own
        // windows — global monitors only observe events routed to other apps — so
        // interacting with the dashboard itself won't dismiss it, and clicking the menu
        // bar icon still goes through togglePopover.
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] _ in
            self?.dismissPopoverSoon()
        }
    }

    private func closeIfAnchorInvalid(_ anchorWindow: NSWindow) {
        guard popover.isShown else { return }

        // Only a *vertical* move means the menu bar itself retracted.
        //
        // The status item uses NSStatusItem.variableLength and its title is rewritten
        // on every metrics tick, so the label's width changes whenever a value gains or
        // loses a digit. Menu bar items are laid out from the right, so a width change
        // shifts the anchor window's origin.x — which is not a reason to dismiss.
        // Comparing the full origin here closed the popover roughly once a second and
        // made the dashboard impossible to interact with.
        if let origin = anchorOrigin, abs(anchorWindow.frame.origin.y - origin.y) > 1 {
            dismissPopoverSoon()
            return
        }

        // Anchor left its screen entirely — nothing valid to point at. Deliberately
        // checks for *no* intersection rather than full containment, so a status item
        // that is merely clipped by a crowded menu bar doesn't dismiss the popover.
        if let screen = anchorWindow.screen, !screen.frame.intersects(anchorWindow.frame) {
            dismissPopoverSoon()
        }
    }

    /// Closes the popover on a later runloop pass rather than inline.
    ///
    /// Both triggers here are window-geometry notifications, which AppKit posts from
    /// inside a CoreAnimation transaction. Tearing the popover down synchronously at
    /// that point re-enters window animation teardown and can over-release
    /// `_NSWindowTransformAnimation`, which showed up as an EXC_BAD_ACCESS in
    /// `objc_release` under `CA::Context::commit_transaction`. Deferring lets the
    /// current transaction finish before the popover goes away.
    private func dismissPopoverSoon() {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.popover.isShown else { return }
            self.popover.performClose(nil)
        }
    }

    private func endTrackingAnchor() {
        for observer in anchorObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        anchorObservers.removeAll()
        anchorOrigin = nil

        if let monitor = outsideClickMonitor {
            NSEvent.removeMonitor(monitor)
            outsideClickMonitor = nil
        }
    }

    // MARK: - Widget refresh

    // Measured, not guessed. chronod honoured app-driven reloads at a strict 30s with
    // no drops, then at 5s (renders every 5.4-6.4s, zero rejections), so the throttle
    // was always the bottleneck rather than the system budget. Now 2s.
    //
    // This is the floor worth using. Each reload wakes the widget extension, which then
    // samples CPU over a 0.4s window before rendering, so a shorter interval would keep
    // that process almost continuously awake for a glanceable snapshot. The dashboard is
    // the live view; widgets are snapshot-based by design and cannot stream.
    private static let widgetReloadInterval: TimeInterval = 2

    /// Pushes a timeline reload to the desktop widget so it tracks the dashboard.
    ///
    /// The widget samples its own data, but left alone it only refreshes on the cadence
    /// WidgetKit grants it — far slower than the app's sampling, and its timeline policy
    /// is only a request, not a guarantee. While the app is running we can drive reloads
    /// so the widget stays close to live.
    ///
    /// Throttled deliberately: WidgetKit budgets reloads per extension and starts
    /// dropping them when one is too chatty, so reloading on every metrics tick would
    /// make the widget update *less* often, not more.
    private func refreshWidgetsIfDue() {
        let now = Date()
        guard now.timeIntervalSince(lastWidgetReload) >= Self.widgetReloadInterval else { return }
        lastWidgetReload = now
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - NSPopoverDelegate

    func popoverDidClose(_ notification: Notification) {
        endTrackingAnchor()
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        // Drop the reference so the next "Settings…" builds a fresh window rather
        // than trying to reuse a closed one. Covers both Done and the close button.
        if (notification.object as? NSWindow) === settingsWin {
            settingsWin = nil
        }
    }

    func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open Dashboard",
                                action: #selector(openPopover), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Settings…",
                                action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit MMetrics",
                                action: #selector(NSApp.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    @objc func openPopover() {
        if let btn = statusItem?.button { togglePopover(btn) }
    }

    // MARK: - Welcome window

    func showWelcomeWindow() {
        let win = NSWindow(
            contentRect:  NSRect(x: 0, y: 0, width: 480, height: 420),
            styleMask:    [.titled, .closable, .fullSizeContentView],
            backing:      .buffered,
            defer:        false
        )
        win.titlebarAppearsTransparent  = true
        win.titleVisibility             = .hidden
        win.isMovableByWindowBackground = true
        win.backgroundColor             = .windowBackgroundColor
        win.contentViewController       = NSHostingController(rootView: WelcomeView())
        win.center()
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        welcomeWin = win
    }

    // MARK: - Settings window

    @objc func openSettings() {
        // Reuse the existing window instead of stacking a new one on every invocation.
        if let existing = settingsWin {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let win = NSWindow(
            contentRect:  NSRect(x: 0, y: 0, width: 360, height: 460),
            styleMask:    [.titled, .closable, .fullSizeContentView],
            backing:      .buffered,
            defer:        false
        )
        win.title                      = "MMetrics Settings"
        win.titlebarAppearsTransparent = true
        // Adaptive so the window tracks the chosen appearance (#14) rather than
        // being pinned to a dark hex value.
        win.backgroundColor            = .windowBackgroundColor
        win.isReleasedWhenClosed       = false

        // SettingsSheet drives dismissal through its isPresented binding. As a
        // standalone window this used to be passed .constant(true), which is
        // read-only — so tapping Done wrote to nothing and the window never closed.
        // Back the binding with an actual close, weakly so the window and its
        // content view don't retain each other.
        let dismiss = Binding<Bool>(
            get: { true },
            set: { [weak win] shouldPresent in
                if !shouldPresent { win?.performClose(nil) }
            }
        )

        // No preferredColorScheme override — SettingsSheet applies the user's
        // Automatic/Light/Dark choice itself.
        win.contentViewController = NSHostingController(
            rootView: SettingsSheet(isPresented: dismiss)
        )
        win.delegate = self
        win.center()
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWin = win
    }
}

// MARK: - Menu bar label

/// Two-row menu bar label: a bold value above a small caption, cells split by thin
/// dividers. Rendered as a template image so it follows the menu bar appearance.
private enum MenuBarLabel {
    struct Cell {
        let value: String
        let label: String
        /// Typical widest value; keeps the cell width stable as digits change.
        /// Rarer wider values (e.g. "100%") grow the cell.
        let widest: String
    }

    private static let height: CGFloat = 22
    private static let cellPadding: CGFloat = 5
    private static let valueAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 11, weight: .medium),
        .foregroundColor: NSColor.black,
    ]
    private static let labelAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 7, weight: .medium),
        .foregroundColor: NSColor.black,
    ]

    static func image(for cells: [Cell]) -> NSImage {
        let widths = cells.map { cell in
            [NSAttributedString(string: cell.widest, attributes: valueAttrs),
             NSAttributedString(string: cell.value, attributes: valueAttrs),
             NSAttributedString(string: cell.label, attributes: labelAttrs)]
                .map { $0.size().width }.max()!
                .rounded(.up) + cellPadding * 2
        }
        let size = NSSize(width: widths.reduce(0, +), height: height)

        let image = NSImage(size: size, flipped: true) { _ in
            var x: CGFloat = 0
            for (i, cell) in cells.enumerated() {
                let w = widths[i]
                if i > 0 {
                    NSColor.black.withAlphaComponent(0.75).setFill()
                    NSRect(x: x - 0.5, y: 3, width: 1, height: height - 6).fill()
                }
                drawCentered(cell.value, attrs: valueAttrs, x: x, width: w, y: 0.5)
                drawCentered(cell.label, attrs: labelAttrs, x: x, width: w, y: 12.5)
                x += w
            }
            return true
        }
        image.isTemplate = true
        return image
    }

    private static func drawCentered(_ text: String, attrs: [NSAttributedString.Key: Any],
                                     x: CGFloat, width: CGFloat, y: CGFloat) {
        let str = NSAttributedString(string: text, attributes: attrs)
        let w = str.size().width
        str.draw(at: NSPoint(x: x + (width - w) / 2, y: y))
    }
}
