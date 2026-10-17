import CoreGraphics
import Darwin

enum DisplayBrightness {
    private typealias Getter = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
    private typealias Setter = @convention(c) (CGDirectDisplayID, Float) -> Int32

    private static let handle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_LAZY)
    private typealias AutoGetter = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Bool>) -> Int32
    private typealias AutoSetter = @convention(c) (CGDirectDisplayID, Bool) -> Int32

    private static let getter: Getter? = symbol("DisplayServicesGetBrightness")
    private static let setter: Setter? = symbol("DisplayServicesSetBrightness")
    private static let autoGetter: AutoGetter? = symbol("DisplayServicesAmbientLightCompensationEnabled")
    private static let autoSetter: AutoSetter? = symbol("DisplayServicesEnableAmbientLightCompensation")

    static var isAutoBrightnessEnabled: Bool? {
        guard let autoGetter, let display = builtInDisplay else { return nil }
        var enabled = false
        guard autoGetter(display, &enabled) == 0 else { return nil }
        return enabled
    }

    @discardableResult
    static func setAutoBrightness(_ enabled: Bool) -> Bool {
        guard let autoSetter, let display = builtInDisplay else { return false }
        return autoSetter(display, enabled) == 0
    }

    static var isAvailable: Bool {
        getter != nil && setter != nil && builtInDisplay != nil
    }

    static func current() -> Double? {
        guard let getter, let display = builtInDisplay else { return nil }
        var value: Float = 0
        guard getter(display, &value) == 0 else { return nil }
        return Double(value)
    }

    static func set(_ value: Double) {
        guard let setter, let display = builtInDisplay else { return }
        _ = setter(display, Float(min(max(value, 0), 1)))
    }

    private static var builtInDisplay: CGDirectDisplayID? {
        var displays = [CGDirectDisplayID](repeating: 0, count: 16)
        var count: UInt32 = 0
        guard CGGetOnlineDisplayList(16, &displays, &count) == .success else { return nil }
        return displays.prefix(Int(count)).first { CGDisplayIsBuiltin($0) != 0 }
    }

    private static func symbol<T>(_ name: String) -> T? {
        guard let handle, let pointer = dlsym(handle, name) else { return nil }
        return unsafeBitCast(pointer, to: T.self)
    }
}
