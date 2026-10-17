public enum SliderLevel {
    public static let boostSpan: Double = 0.5
    public static let fullBrightness: Double = 0.995

    public static func upperBound(boostEnabled: Bool) -> Double {
        boostEnabled ? 1 + boostSpan : 1
    }

    public static func effectiveStrength(brightness: Double, strength: Double) -> Double {
        brightness >= fullBrightness ? clamp(strength) : 0
    }

    public static func level(brightness: Double, strength: Double, boostEnabled: Bool) -> Double {
        let brightness = clamp(brightness)
        guard boostEnabled, brightness >= fullBrightness else { return brightness }
        return 1 + clamp(strength) * boostSpan
    }

    public static func split(level: Double, boostEnabled: Bool) -> (brightness: Double, strength: Double) {
        let level = min(max(level, 0), upperBound(boostEnabled: boostEnabled))
        return (min(level, 1), max(level - 1, 0) / boostSpan)
    }

    public static func percent(level: Double, headroom: Float = BoostMath.defaultCap) -> Int {
        guard level > 1 else { return Int((clamp(level) * 100).rounded()) }
        let strength = (min(level, 1 + boostSpan) - 1) / boostSpan
        return Int((Double(BoostMath.factor(headroom: headroom, strength: Float(strength))) * 100).rounded())
    }

    private static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
