import AppKit
import ApplicationServices

final class BrightnessKeyTap {
    private enum Action: Sendable {
        case pass
        case swallow
        case step(up: Bool)
        case reenable
    }

    private nonisolated static let systemDefinedEventType = CGEventType(rawValue: 14)!
    private nonisolated static let auxControlButtonsSubtype: Int16 = 8
    private nonisolated static let brightnessUpKey = 2
    private nonisolated static let brightnessDownKey = 3
    private nonisolated static let keyDownState = 0xA

    private let onStep: (Bool) -> Void
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?

    init(onStep: @escaping (Bool) -> Void) {
        self.onStep = onStep
    }

    static func requestAccess() -> Bool {
        AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
    }

    var isRunning: Bool { tap != nil }

    @discardableResult
    func start() -> Bool {
        guard tap == nil else { return true }
        guard AXIsProcessTrusted() else { return false }
        let mask = CGEventMask(1) << Self.systemDefinedEventType.rawValue
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, type, event, context in
                let action = BrightnessKeyTap.action(for: type, event: event)
                if let context {
                    MainActor.assumeIsolated {
                        Unmanaged<BrightnessKeyTap>.fromOpaque(context).takeUnretainedValue().perform(action)
                    }
                }
                switch action {
                case .swallow, .step: return nil
                case .pass, .reenable: return Unmanaged.passUnretained(event)
                }
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return false }
        let source = CFMachPortCreateRunLoopSource(nil, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        self.tap = tap
        self.source = source
        return true
    }

    func stop() {
        guard let tap else { return }
        CGEvent.tapEnable(tap: tap, enable: false)
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        CFMachPortInvalidate(tap)
        self.tap = nil
        self.source = nil
    }

    private func perform(_ action: Action) {
        switch action {
        case .reenable:
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
        case .step(let up):
            onStep(up)
        case .pass, .swallow:
            break
        }
    }

    private nonisolated static func action(for type: CGEventType, event: CGEvent) -> Action {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput { return .reenable }
        guard
            type == systemDefinedEventType,
            let nsEvent = NSEvent(cgEvent: event),
            nsEvent.subtype.rawValue == auxControlButtonsSubtype
        else { return .pass }

        let key = (nsEvent.data1 & 0xFFFF_0000) >> 16
        guard key == brightnessUpKey || key == brightnessDownKey else { return .pass }
        return (nsEvent.data1 & 0xFF00) >> 8 == keyDownState ? .step(up: key == brightnessUpKey) : .swallow
    }
}
