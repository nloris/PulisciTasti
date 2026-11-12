import AppKit
import SwiftUI
import ApplicationServices
import Carbon

func blocksKeyboard(_ raw: UInt32) -> Bool {
    // NX_SYSDEFINED (14) carries media/brightness keys. Mouse events are omitted.
    return [CGEventType.keyDown.rawValue, CGEventType.keyUp.rawValue,
            CGEventType.flagsChanged.rawValue, 14].contains(raw)
}

func remainingSeconds(deadline: Date?, now: Date) -> Int? {
    deadline.map { max(0, Int(ceil($0.timeIntervalSince(now)))) }
}

final class KeyboardLock: ObservableObject {
    @Published var presses = 0
    @Published var lastKey: Int64? = nil
    @Published var elapsed = 0
    @Published var remaining: Int? = nil
    @Published var duration = 0
    @Published var finished = false
    @Published var english = !(Locale.preferredLanguages.first?.hasPrefix("it") ?? false)
    var mayAutoStart = true
    var demo = false
    private var startedAt: Date?
    private var deadline: Date?
    private var pendingPresses = 0
    private var pendingKey: Int64?
    private var lastPressAt = Date.distantPast
    func text(_ it: String, _ en: String) -> String { english ? en : it }
    func setDuration(_ seconds: Int, now: Date = Date()) {
        duration = seconds
        deadline = locked && seconds > 0 ? now.addingTimeInterval(Double(seconds)) : nil
        remaining = remainingSeconds(deadline: deadline, now: now)
    }
    func beginSession() {
        finished = false
        presses = 0
        pendingPresses = 0
        elapsed = 0
        startedAt = Date()
        locked = true
        mayAutoStart = false
        setDuration(duration)
    }
    func tick(now: Date = Date()) {
        guard locked else { return }
        if let startedAt { elapsed = max(0, Int(now.timeIntervalSince(startedAt))) }
        remaining = remainingSeconds(deadline: deadline, now: now)
        if remaining == 0 {
            stop()
            finished = true
            return
        }
        if presses != pendingPresses { presses = pendingPresses }
        let visibleKey = now.timeIntervalSince(lastPressAt) < 0.22 ? pendingKey : nil
        if lastKey != visibleKey { lastKey = visibleKey }
    }

    @Published var locked = false
    @Published var message = "Serve un permesso di macOS, solo la prima volta."
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?

    func start() {
        guard !locked else { return }
        if demo { beginSession(); return }
        guard AXIsProcessTrusted() else {
            message = text("Abilita PulisciTasti in Accessibilità, poi torna qui.", "Enable PulisciTasti in Accessibility, then return here.")
            return
        }
        guard !IsSecureEventInputEnabled() else {
            message = text("Chiudi eventuali campi password e torna qui per attivare il blocco.", "Close any password fields, then return here to lock the keyboard.")
            return
        }
        let mask = [CGEventType.keyDown.rawValue, CGEventType.keyUp.rawValue,
                    CGEventType.flagsChanged.rawValue, UInt32(14)]
            .reduce(CGEventMask(0)) { $0 | (CGEventMask(1) << $1) }
        guard let port = CGEvent.tapCreate(tap: .cghidEventTap,
            place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: mask,
            callback: { _, type, event, context in
                guard let context else { return Unmanaged.passUnretained(event) }
                let owner = Unmanaged<KeyboardLock>.fromOpaque(context).takeUnretainedValue()
                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                    if owner.locked, let tap = owner.tap { CGEvent.tapEnable(tap: tap, enable: true) }
                    return Unmanaged.passUnretained(event)
                }
                if owner.locked && blocksKeyboard(type.rawValue) {
                    if type == .keyDown {
                        owner.pendingPresses += 1
                        owner.pendingKey = event.getIntegerValueField(.keyboardEventKeycode)
                        owner.lastPressAt = Date()
                    }
                    return nil
                }
                return Unmanaged.passUnretained(event)
            }, userInfo: Unmanaged.passUnretained(self).toOpaque()) else {
                message = text("Il blocco non è attivo. Controlla Accessibilità e riapri l’app.", "Keyboard not locked. Check Accessibility and reopen the app.")
                return
            }
        guard let runSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0) else {
            CFMachPortInvalidate(port)
            message = text("Non riesco ad attivare il blocco. Chiudi e riapri l’app.", "Could not lock the keyboard. Quit and reopen the app.")
            return
        }
        tap = port
        source = runSource
        beginSession()
        CFRunLoopAddSource(CFRunLoopGetMain(), runSource, .commonModes)
        CGEvent.tapEnable(tap: port, enable: true)
    }

    func checkHealth() {
        guard locked else { return }
        if !AXIsProcessTrusted() || IsSecureEventInputEnabled() {
            stop()
            message = text("Blocco interrotto da macOS. Torna qui e riattivalo prima di pulire.", "macOS interrupted the lock. Reactivate it before cleaning.")
        } else if let tap, !CGEvent.tapIsEnabled(tap: tap) {
            CGEvent.tapEnable(tap: tap, enable: true)
            if !CGEvent.tapIsEnabled(tap: tap) {
                stop()
                message = text("Blocco interrotto. Chiudi e riapri l’app.", "Lock interrupted. Quit and reopen the app.")
            }
        }
    }

    func stop() {
        locked = false
        deadline = nil
        remaining = nil
        lastKey = nil
        pendingKey = nil
        lastPressAt = .distantPast
        if let tap { CGEvent.tapEnable(tap: tap, enable: false); CFMachPortInvalidate(tap) }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        source = nil
        tap = nil
    }

    func openPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}

struct KeyboardIllustration: View {
    let active: Bool
    let lastKey: Int64?
    @Environment(\.colorScheme) var scheme
    private let rows: [[Int64]] = [
        [53, 122, 120, 99, 118, 96, 97, 98, 100, 101, 109, 103, 111],
        [50, 18, 19, 20, 21, 23, 22, 26, 28, 25, 29, 27, 24, 51],
        [48, 12, 13, 14, 15, 17, 16, 32, 34, 31, 35, 33, 30, 42],
        [57, 0, 1, 2, 3, 5, 4, 38, 40, 37, 41, 39, 36],
        [56, 6, 7, 8, 9, 11, 45, 46, 43, 47, 44, 60],
        [63, 59, 58, 55, 49, 54, 61, 123, 125, 126, 124]
    ]
    var body: some View {
        VStack(spacing: 5) {
            ForEach(rows.indices, id: \.self) { row in
                HStack(spacing: 5) {
                    ForEach(rows[row], id: \.self) { key in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(lastKey == key ? Color(red: 0.15, green: 0.58, blue: 0.39) : Color.primary.opacity(scheme == .dark ? 0.13 : 0.055))
                            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Color.primary.opacity(0.07), lineWidth: 0.6))
                            .frame(maxWidth: .infinity)
                            .frame(width: key == 49 ? 130 : nil, height: row == 0 ? 12 : 20)
                            .shadow(color: .black.opacity(0.04), radius: 0, y: 1)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.primary.opacity(0.025), in: RoundedRectangle(cornerRadius: 17))
        .overlay(RoundedRectangle(cornerRadius: 17).strokeBorder(Color.primary.opacity(0.09)))
        .opacity(active ? 1 : 0.55)
        .animation(.easeOut(duration: 0.15), value: lastKey)
        .accessibilityHidden(true)
    }
}

struct MainView: View {
    @ObservedObject var keyboard: KeyboardLock
    let quit: () -> Void
    @Environment(\.colorScheme) var scheme
    private let green = Color(red: 0.15, green: 0.58, blue: 0.39)
    func t(_ it: String, _ en: String) -> String { keyboard.text(it, en) }
    func clock(_ seconds: Int) -> String { String(format: "%02d:%02d", seconds / 60, seconds % 60) }
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 9) {
                Image(systemName: "sparkles").foregroundStyle(green)
                Text("PulisciTasti").font(.system(size: 14, weight: .semibold))
                Spacer()
                Button(keyboard.english ? "EN" : "IT") { keyboard.english.toggle() }
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary).buttonStyle(.plain)
                    .help(t("Cambia lingua", "Change language"))
                Button(action: quit) {
                    Image(systemName: "xmark").font(.system(size: 12, weight: .semibold))
                        .frame(width: 30, height: 30)
                        .background(Color.primary.opacity(0.055), in: Circle())
                        .contentShape(Circle())
                }.buttonStyle(.plain).padding(.leading, 10)
                    .help(t("Sblocca la tastiera e chiudi", "Unlock keyboard and quit"))
                    .accessibilityLabel(t("Sblocca e chiudi", "Unlock and quit"))
            }
            HStack(spacing: 6) {
                Circle().fill(keyboard.locked ? green : .orange).frame(width: 6, height: 6)
                Text(keyboard.demo ? "DEMO · " + t("NESSUN BLOCCO REALE", "KEYBOARD NOT BLOCKED") :
                        (keyboard.locked ? t("TASTIERA PROTETTA", "KEYBOARD LOCKED") : t("TASTIERA LIBERA", "KEYBOARD UNLOCKED")))
                    .font(.system(size: 10, weight: .semibold, design: .monospaced)).tracking(1.2)
            }.foregroundStyle(.secondary).padding(.top, 28)
            Text(keyboard.locked ? t("Un momento di cura.", "A little moment of care.") :
                    keyboard.finished ? t("Tutto pulito. Si riparte.", "All clean. All yours.") : t("Prima, un piccolo permesso.", "One little permission first."))
                .font(.system(size: 29, weight: .semibold, design: .rounded)).tracking(-0.8).padding(.top, 12)
            Text(keyboard.locked ? t("Pulisci i tasti. Al resto pensiamo noi.", "Wipe the keys. We’ll take care of the rest.") :
                    keyboard.finished ? t("La tastiera è di nuovo attiva.", "Your keyboard is ready to use again.") :
                    t("Consenti Accessibilità per bloccare i tasti.", "Allow Accessibility to block key presses."))
                .font(.system(size: 13)).foregroundStyle(.secondary).padding(.top, 8)
            KeyboardIllustration(active: keyboard.locked, lastKey: keyboard.lastKey)
                .padding(.top, 26).padding(.horizontal, 8)
            if keyboard.locked || keyboard.finished {
                HStack {
                    Label(t("Trackpad attivo", "Trackpad active"), systemImage: "cursorarrow")
                    Spacer()
                    Text("\(keyboard.presses) " + t("pressioni bloccate", "presses blocked")).monospacedDigit()
                }.font(.system(size: 11)).foregroundStyle(.secondary).padding(.top, 16).padding(.horizontal, 9)
                HStack(spacing: 5) {
                    Image(systemName: "timer").foregroundStyle(.secondary).padding(.trailing, 3)
                    ForEach([0, 120, 300, 600], id: \.self) { seconds in
                        Button(seconds == 0 ? t("Senza limite", "No limit") : "\(seconds / 60) min") {
                            keyboard.setDuration(seconds)
                        }.buttonStyle(.plain).font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 10).padding(.vertical, 7)
                            .background(keyboard.duration == seconds ? Color.primary.opacity(0.08) : .clear, in: Capsule())
                            .accessibilityLabel(seconds == 0 ? t("Disattiva lo sblocco automatico", "Disable automatic unlock") : t("Sblocca tra", "Unlock in") + " \(seconds / 60) " + t("minuti", "minutes"))
                    }
                    Spacer(minLength: 0)
                    Text(clock(keyboard.remaining ?? keyboard.elapsed)).monospacedDigit()
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(keyboard.remaining != nil && keyboard.remaining! <= 10 ? .orange : .secondary)
                }.padding(7).background(Color.primary.opacity(0.025), in: RoundedRectangle(cornerRadius: 12)).padding(.top, 22)
                Text(keyboard.finished ? t("Sessione terminata. Puoi chiudere o bloccare di nuovo.", "Session complete. Close the app or lock again.") : keyboard.remaining != nil ? t("Alla fine del timer la tastiera si sblocca automaticamente.", "The keyboard unlocks automatically when the timer ends.") : t("Quando hai finito, clicca la X per sbloccare e uscire.", "When you’re done, click × to unlock and quit."))
                    .font(.system(size: 11)).foregroundStyle(.secondary).padding(.top, 12)
            } else {
                Text(keyboard.message).font(.system(size: 12)).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).frame(height: 42).padding(.top, 14)
            }
            if !keyboard.locked {
                Button(keyboard.finished || AXIsProcessTrusted() ? t("Blocca la tastiera", "Lock keyboard") : t("Apri Accessibilità", "Open Accessibility")) {
                    if keyboard.demo || AXIsProcessTrusted() { keyboard.start() } else { keyboard.openPermissions() }
                }.buttonStyle(.plain).font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white).padding(.horizontal, 23).padding(.vertical, 11)
                    .background(green, in: Capsule()).padding(.top, 15)
            }
            Spacer(minLength: 14)
            HStack(spacing: 5) {
                Image(systemName: "power").font(.system(size: 9))
                Text(t("Accensione e Touch ID restano attivi.", "Power and Touch ID remain active."))
            }.font(.system(size: 10)).foregroundStyle(.tertiary)
        }
        .padding(28).frame(width: 560, height: 590)
        .background(Color(nsColor: .windowBackgroundColor))
        .tint(green)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    let keyboard = KeyboardLock()
    var window: NSWindow!
    var status: NSStatusItem!
    var timer: Timer?
    let preview = CommandLine.arguments.contains("--preview")

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        let menu = NSMenu()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Sblocca e chiudi PulisciTasti", action: #selector(quit), keyEquivalent: "q").target = self
        let root = NSMenuItem(); root.submenu = appMenu; menu.addItem(root); NSApp.mainMenu = menu
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 560, height: 590),
                          styleMask: [.titled, .closable, .fullSizeContentView], backing: .buffered, defer: false)
        window.title = "PulisciTasti"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.delegate = self
        window.contentView = NSHostingView(rootView: MainView(keyboard: keyboard, quit: { [weak self] in self?.quit() }))
        window.center()
        window.makeKeyAndOrderFront(nil)
        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        status.button?.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "PulisciTasti")
        status.button?.toolTip = "PulisciTasti — clicca per sbloccare e chiudere"
        status.button?.target = self
        status.button?.action = #selector(quit)
        NSApp.activate(ignoringOtherApps: true)
        keyboard.demo = preview
        if preview { keyboard.beginSession() } else { keyboard.start() }
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.keyboard.tick()
            if !self.preview { self.keyboard.checkHealth() }
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        if !preview, window != nil, keyboard.mayAutoStart { keyboard.start() }
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        window.makeKeyAndOrderFront(nil)
        return true
    }
    func windowWillClose(_ notification: Notification) { quit() }
    func applicationWillTerminate(_ notification: Notification) { timer?.invalidate(); keyboard.stop() }
    @objc func quit() { keyboard.stop(); NSApp.terminate(nil) }
}

if CommandLine.arguments.contains("--self-test") {
    for type in [CGEventType.keyDown, .keyUp, .flagsChanged] { precondition(blocksKeyboard(type.rawValue)) }
    precondition(blocksKeyboard(14))
    for type in [CGEventType.leftMouseDown, .leftMouseUp, .rightMouseDown, .mouseMoved, .leftMouseDragged, .scrollWheel] {
        precondition(!blocksKeyboard(type.rawValue))
    }
    let now = Date(timeIntervalSince1970: 1_000)
    precondition(remainingSeconds(deadline: nil, now: now) == nil)
    precondition(remainingSeconds(deadline: now.addingTimeInterval(0.2), now: now) == 1)
    precondition(remainingSeconds(deadline: now.addingTimeInterval(-1), now: now) == 0)
    let session = KeyboardLock()
    session.demo = true
    session.start()
    precondition(session.locked && !session.mayAutoStart)
    session.setDuration(120, now: now)
    session.tick(now: now.addingTimeInterval(119))
    precondition(session.locked && session.remaining == 1)
    session.tick(now: now.addingTimeInterval(120))
    precondition(!session.locked && session.finished && !session.mayAutoStart)
    session.start()
    session.setDuration(0)
    session.tick(now: now.addingTimeInterval(10_000))
    precondition(session.locked && session.remaining == nil)
    session.stop()
    precondition(!session.locked)
    print("PASS: keyboard/mouse filtering, timer expiry, no automatic re-lock, unlimited mode, manual unlock.")
} else if let index = CommandLine.arguments.firstIndex(of: "--render-preview"), CommandLine.arguments.count > index + 1 {
    // Offscreen asset generation for documentation; never installs an event tap.
    let app = NSApplication.shared
    app.setActivationPolicy(.prohibited)
    let model = KeyboardLock()
    model.demo = true
    model.english = true
    model.beginSession()
    model.presses = 128
    model.elapsed = 42
    model.lastKey = 14
    if CommandLine.arguments.contains("--finished") { model.stop(); model.finished = true }
    if CommandLine.arguments.contains("--onboarding") {
        model.stop()
        model.message = "Enable PulisciTasti in Accessibility, then return here."
    }
    let view = NSHostingView(rootView: MainView(keyboard: model, quit: {}))
    view.appearance = NSAppearance(named: CommandLine.arguments.contains("--light") ? .aqua : .darkAqua)
    view.frame = NSRect(x: 0, y: 0, width: 560, height: 590)
    view.layoutSubtreeIfNeeded()
    let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds)!
    view.cacheDisplay(in: view.bounds, to: bitmap)
    try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[index + 1]))
} else {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}
