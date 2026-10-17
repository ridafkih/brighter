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

struct SliderLevelTests {
    @Test func boostOffIsPlainBrightness() {
        #expect(SliderLevel.upperBound(boostEnabled: false) == 1)
        #expect(SliderLevel.level(brightness: 0.6, strength: 0.8, boostEnabled: false) == 0.6)
        let parts = SliderLevel.split(level: 1.3, boostEnabled: false)
        #expect(parts.brightness == 1)
        #expect(parts.strength == 0)
    }

    @Test(arguments: [(0.8, 80), (1.0, 100), (1.25, 130), (1.5, 160), (2.0, 160)])
    func percentCountsPastOneHundred(level: Double, expected: Int) {
        #expect(SliderLevel.percent(level: level) == expected)
    }

    @Test func percentRespectsLimitedHeadroom() {
        #expect(SliderLevel.percent(level: 1.5, headroom: 1.3) == 130)
    }

    @Test(arguments: [(0.999, 0.99, true), (0.96, 0.955, true), (1.0, 0.997, false), (1.0, 0.9375, false), (0.99, 0.97, false)])
    func autoBrightnessDriftIsSeparatedFromKeyPresses(previous: Double, current: Double, isDrift: Bool) {
        #expect(SliderLevel.isDrift(from: previous, to: current) == isDrift)
    }

    @Test func strengthPausesBelowFullBrightness() {
        #expect(SliderLevel.effectiveStrength(brightness: 0.97, strength: 0.75) == 0)
        #expect(SliderLevel.effectiveStrength(brightness: 0.998, strength: 0.75) == 0.75)
        #expect(SliderLevel.effectiveStrength(brightness: 1, strength: 0.75) == 0.75)
    }

    @Test func boostOnlyCountsAtFullBrightness() {
        #expect(SliderLevel.level(brightness: 0.6, strength: 0.8, boostEnabled: true) == 0.6)
        #expect(SliderLevel.level(brightness: 1, strength: 0.5, boostEnabled: true) == 1.25)
    }

    @Test(arguments: [(0.4, 0.4, 0.0), (1.0, 1.0, 0.0), (1.25, 1.0, 0.5), (1.5, 1.0, 1.0), (2.0, 1.0, 1.0)])
    func splitAroundTheNotch(level: Double, brightness: Double, strength: Double) {
        let parts = SliderLevel.split(level: level, boostEnabled: true)
        #expect(parts.brightness == brightness)
        #expect(abs(parts.strength - strength) < 0.0001)
    }
}
