public struct GammaTable: Equatable, Sendable {
    public var red: [Float]
    public var green: [Float]
    public var blue: [Float]

    public init(red: [Float], green: [Float], blue: [Float]) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    public var count: Int { red.count }

    public func scaled(by factor: Float) -> GammaTable {
        GammaTable(
            red: red.map { $0 * factor },
            green: green.map { $0 * factor },
            blue: blue.map { $0 * factor }
        )
    }

    public func clampedToUnit() -> GammaTable {
        GammaTable(
            red: red.map { min(max($0, 0), 1) },
            green: green.map { min(max($0, 0), 1) },
            blue: blue.map { min(max($0, 0), 1) }
        )
    }

    public func isClose(to other: GammaTable, tolerance: Float = 0.002) -> Bool {
        guard count == other.count else { return false }
        return zip([red, green, blue], [other.red, other.green, other.blue]).allSatisfy { lhs, rhs in
            zip(lhs, rhs).allSatisfy { abs($0 - $1) <= tolerance }
        }
    }
}
