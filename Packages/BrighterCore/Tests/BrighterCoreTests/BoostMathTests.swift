import Testing
@testable import BrighterCore

struct BoostMathTests {
    @Test func noHeadroomMeansNoBoost() {
        #expect(BoostMath.factor(headroom: 1, strength: 1) == 1)
        #expect(BoostMath.factor(headroom: 0.5, strength: 1) == 1)
    }

    @Test func zeroStrengthMeansNoBoost() {
        #expect(BoostMath.factor(headroom: 4, strength: 0) == 1)
    }

    @Test(arguments: [(Float(2), Float(1), Float(1.6)), (2, 0.5, 1.3), (1.4, 1, 1.4), (16, 1, 1.6)])
    func factorIsCappedByHeadroomAndCap(headroom: Float, strength: Float, expected: Float) {
        #expect(abs(BoostMath.factor(headroom: headroom, strength: strength) - expected) < 0.0001)
    }

    @Test func strengthIsClamped() {
        #expect(BoostMath.factor(headroom: 2, strength: 3) == BoostMath.factor(headroom: 2, strength: 1))
    }

    @Test func fadeEndsAtTarget() {
        let steps = BoostMath.fadeSteps(from: 1, to: 1.5, count: 5)
        #expect(steps.count == 5)
        #expect(steps.last == 1.5)
        #expect(steps == steps.sorted())
    }
}

struct GammaTableTests {
    let identity = GammaTable(red: [0, 0.5, 1], green: [0, 0.5, 1], blue: [0, 0.5, 1])

    @Test func scalingMultipliesEveryChannel() {
        let scaled = identity.scaled(by: 1.5)
        #expect(scaled.red == [0, 0.75, 1.5])
        #expect(scaled.green == scaled.red)
        #expect(scaled.blue == scaled.red)
    }

    @Test func clampingMatchesClampedReadback() {
        let boosted = identity.scaled(by: 1.5)
        let readback = GammaTable(red: [0, 0.75, 1], green: [0, 0.75, 1], blue: [0, 0.75, 1])
        #expect(boosted.clampedToUnit() == readback)
        #expect(!identity.clampedToUnit().isClose(to: boosted.clampedToUnit()))
    }

    @Test func closenessRespectsTolerance() {
        #expect(identity.isClose(to: identity.scaled(by: 1.001)))
        #expect(!identity.isClose(to: identity.scaled(by: 1.1)))
        #expect(!identity.isClose(to: GammaTable(red: [0], green: [0], blue: [0])))
    }
}
