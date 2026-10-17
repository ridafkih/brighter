import AppKit
import BrighterCore
import Observation
import os

@Observable
final class BoostController {
    enum Status: Equatable {
        case off
        case engaging
        case boosted
        case suspended
        case unsupported
        case failed
    }

    private struct Session {
        let displayID: CGDirectDisplayID
        let window: EDRTriggerWindow
        let gamma: GammaController
        var factor: Float = 1
    }

    private static let log = Logger(subsystem: "com.ridafkih.Brighter", category: "boost")

    private enum Keys {
        static let enabled = "enabled"
        static let restoreAutoBrightness = "restoreAutoBrightness"
    }

    var isEnabled: Bool {
        didSet {
            guard isEnabled != oldValue else { return }
            defaults.set(isEnabled, forKey: Keys.enabled)
            if isEnabled { strength = 0 }
            isEnabled ? engage() : disengage(status: .off)
        }
    }

    private(set) var brightness: Double = DisplayBrightness.current() ?? 1

    var isBoosted: Bool { status == .boosted }

    var level: Double {
        get { SliderLevel.level(brightness: brightness, strength: strength, boostEnabled: isBoosted) }
        set {
            let parts = SliderLevel.split(level: newValue, boostEnabled: isBoosted)
            if abs(parts.brightness - brightness) > 0.0005 {
                brightness = parts.brightness
                DisplayBrightness.set(parts.brightness)
                lastBrightnessWrite = .now
            }
            if isBoosted, abs(parts.strength - strength) > 0.0005 { strength = parts.strength }
        }
    }

    func refreshBrightness() {
        guard ContinuousClock.now - lastBrightnessWrite > .seconds(1), let current = DisplayBrightness.current() else { return }
        guard abs(current - brightness) > 0.002 else { return }
        brightness = current
        Self.log.info("brightness \(current)")
        if status == .boosted { applyTargets() }
    }

    var strength: Double {
        didSet {
            if status == .boosted { applyTargets() }
        }
    }

    private(set) var status: Status = .off {
        didSet { if status != oldValue { Self.log.info("status \(String(describing: self.status), privacy: .public) brightness \(self.brightness)") } }
    }
    var levelPercent: Int {
        let headroom = sessions.map { Self.headroom(for: $0.displayID) }.max() ?? BoostMath.defaultCap
        return SliderLevel.percent(level: level, headroom: headroom)
    }

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var sessions: [Session] = []
    @ObservationIgnored private var engageTask: Task<Void, Never>?
    @ObservationIgnored private var monitorTask: Task<Void, Never>?
    @ObservationIgnored private var screenSignature: [CGDirectDisplayID] = []
    @ObservationIgnored private var observers: [(NotificationCenter, NSObjectProtocol)] = []
    @ObservationIgnored private var lastBrightnessWrite: ContinuousClock.Instant = .now - .seconds(10)

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isEnabled = defaults.bool(forKey: Keys.enabled)
        strength = 0
        screenSignature = Self.currentSignature()
        restoreAutoBrightness()
        observeSystemEvents()
        if isEnabled { engage() }
    }

    private func engage(after delay: Duration = .zero) {
        engageTask?.cancel()
        engageTask = Task {
            if delay > .zero {
                try? await Task.sleep(for: delay)
                guard !Task.isCancelled else { return }
            }
            await performEngage()
        }
    }

    private func performEngage() async {
        teardown()
        status = .engaging

        let screens = NSScreen.screens.filter { $0.maximumPotentialExtendedDynamicRangeColorComponentValue > 1 }
        guard !screens.isEmpty else {
            status = .unsupported
            return
        }

        sessions = screens.compactMap { screen in
            guard
                let displayID = screen.displayID,
                let gamma = GammaController(displayID: displayID),
                let window = EDRTriggerWindow(screen: screen)
            else { return nil }
            window.orderFrontRegardless()
            return Session(displayID: displayID, window: window, gamma: gamma)
        }

        guard await waitForHeadroom(), !Task.isCancelled else {
            guard !Task.isCancelled else { return }
            teardown()
            status = .failed
            engage(after: .seconds(30))
            return
        }

        await fadeToTargets()
        guard !Task.isCancelled else { return }
        status = .boosted
        suspendAutoBrightness()
        startMonitoring()
    }

    private func waitForHeadroom(timeout: Duration = .seconds(10)) async -> Bool {
        let deadline = ContinuousClock.now + timeout
        while ContinuousClock.now < deadline {
            if !sessions.isEmpty, sessions.allSatisfy({ Self.headroom(for: $0.displayID) > BoostMath.minimumHeadroom }) {
                return true
            }
            try? await Task.sleep(for: .milliseconds(100))
            if Task.isCancelled { return false }
        }
        return false
    }

    private func targetFactor(for displayID: CGDirectDisplayID) -> Float {
        BoostMath.factor(headroom: Self.headroom(for: displayID), strength: Float(strength))
    }

    private func fadeToTargets() async {
        let plans = sessions.map { session in
            BoostMath.fadeSteps(from: session.factor, to: targetFactor(for: session.displayID), count: 10)
        }
        for step in 0..<10 {
            guard !Task.isCancelled else { return }
            for index in sessions.indices {
                let factor = plans[index][step]
                sessions[index].gamma.apply(factor: factor)
                sessions[index].factor = factor
            }
            try? await Task.sleep(for: .milliseconds(20))
        }
    }

    private func applyTargets(force: Bool = false) {
        for index in sessions.indices {
            let target = targetFactor(for: sessions[index].displayID)
            guard force || abs(target - sessions[index].factor) > 0.005 else { continue }
            sessions[index].gamma.apply(factor: target)
            Self.log.info("factor \(target) display \(self.sessions[index].displayID)")
            sessions[index].factor = target
        }
    }

    private func startMonitoring() {
        monitorTask?.cancel()
        monitorTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { return }
                refreshBrightness()
                applyTargets(force: sessions.contains { $0.gamma.hasDrifted })
            }
        }
    }

    private func disengage(status newStatus: Status) {
        engageTask?.cancel()
        engageTask = nil
        teardown()
        status = newStatus
    }

    private func teardown() {
        monitorTask?.cancel()
        monitorTask = nil
        for session in sessions {
            session.gamma.restore()
            session.window.close()
        }
        sessions = []
        restoreAutoBrightness()
    }

    private func suspendAutoBrightness() {
        guard DisplayBrightness.isAutoBrightnessEnabled == true else { return }
        defaults.set(true, forKey: Keys.restoreAutoBrightness)
        if DisplayBrightness.setAutoBrightness(false) {
            Self.log.info("auto-brightness suspended")
        } else {
            defaults.removeObject(forKey: Keys.restoreAutoBrightness)
        }
    }

    private func restoreAutoBrightness() {
        guard defaults.bool(forKey: Keys.restoreAutoBrightness) else { return }
        DisplayBrightness.setAutoBrightness(true)
        defaults.removeObject(forKey: Keys.restoreAutoBrightness)
        Self.log.info("auto-brightness restored")
    }

    private func observeSystemEvents() {
        let app = NotificationCenter.default
        let workspace = NSWorkspace.shared.notificationCenter

        observe(app, NSApplication.didChangeScreenParametersNotification) { controller in
            let signature = Self.currentSignature()
            guard signature != controller.screenSignature else { return }
            controller.screenSignature = signature
            if controller.isEnabled { controller.engage(after: .seconds(1)) }
        }
        for name in [NSWorkspace.willSleepNotification, NSWorkspace.screensDidSleepNotification, NSWorkspace.sessionDidResignActiveNotification] {
            observe(workspace, name) { controller in
                if controller.isEnabled { controller.disengage(status: .suspended) }
            }
        }
        for name in [NSWorkspace.didWakeNotification, NSWorkspace.screensDidWakeNotification, NSWorkspace.sessionDidBecomeActiveNotification] {
            observe(workspace, name) { controller in
                if controller.isEnabled { controller.engage(after: .seconds(2)) }
            }
        }
        observe(app, NSApplication.willTerminateNotification) { controller in
            controller.teardown()
        }
    }

    private func observe(_ center: NotificationCenter, _ name: Notification.Name, handler: @escaping @MainActor (BoostController) -> Void) {
        let token = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                handler(self)
            }
        }
        observers.append((center, token))
    }

    private static func currentSignature() -> [CGDirectDisplayID] {
        NSScreen.screens.compactMap(\.displayID).sorted()
    }

    private static func headroom(for displayID: CGDirectDisplayID) -> Float {
        let screen = NSScreen.screens.first { $0.displayID == displayID }
        return Float(screen?.maximumExtendedDynamicRangeColorComponentValue ?? 1)
    }
}

extension NSScreen {
    var displayID: CGDirectDisplayID? {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
    }
}
