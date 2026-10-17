import CoreGraphics
import Darwin

enum DisplayBrightness {
    private typealias Getter = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
    private typealias Setter = @convention(c) (CGDirectDisplayID, Float) -> Int32

    private static let handle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_LAZY)
    private static let getter: Getter? = symbol("DisplayServicesGetBrightness")
    private static let setter: Setter? = symbol("DisplayServicesSetBrightness")

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
