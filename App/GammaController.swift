import BrighterCore
import CoreGraphics

final class GammaController {
    let displayID: CGDirectDisplayID
    private let original: GammaTable
    private var applied: GammaTable?

    init?(displayID: CGDirectDisplayID) {
        guard let table = Self.read(displayID) else { return nil }
        self.displayID = displayID
        self.original = table
    }

    @discardableResult
    func apply(factor: Float) -> Bool {
        let table = original.scaled(by: factor)
        guard Self.write(table, to: displayID) else { return false }
        applied = table
        return true
    }

    var hasDrifted: Bool {
        guard let applied else { return false }
        guard let current = Self.read(displayID) else { return true }
        return !current.clampedToUnit().isClose(to: applied.clampedToUnit())
    }

    func restore() {
        Self.write(original, to: displayID)
        applied = nil
    }

    private static func read(_ displayID: CGDirectDisplayID) -> GammaTable? {
        let capacity = CGDisplayGammaTableCapacity(displayID)
        guard capacity > 0 else { return nil }
        var red = [CGGammaValue](repeating: 0, count: Int(capacity))
        var green = red
        var blue = red
        var count: UInt32 = 0
        guard CGGetDisplayTransferByTable(displayID, capacity, &red, &green, &blue, &count) == .success, count > 0 else {
            return nil
        }
        let size = Int(count)
        return GammaTable(red: Array(red.prefix(size)), green: Array(green.prefix(size)), blue: Array(blue.prefix(size)))
    }

    @discardableResult
    private static func write(_ table: GammaTable, to displayID: CGDirectDisplayID) -> Bool {
        CGSetDisplayTransferByTable(displayID, UInt32(table.count), table.red, table.green, table.blue) == .success
    }
}
