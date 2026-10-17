public enum BoostMath {
    public static let defaultCap: Float = 1.6
    public static let minimumHeadroom: Float = 1.05

    public static func factor(headroom: Float, strength: Float, cap: Float = defaultCap) -> Float {
        let available = min(max(headroom, 1), cap)
        let clampedStrength = min(max(strength, 0), 1)
        return 1 + (available - 1) * clampedStrength
    }

    public static func fadeSteps(from start: Float, to end: Float, count: Int) -> [Float] {
        guard count > 1 else { return [end] }
        return (1...count).map { step in
            start + (end - start) * Float(step) / Float(count)
        }
    }
}
