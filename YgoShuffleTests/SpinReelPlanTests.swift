import Foundation
import Testing
@testable import YgoShuffle

struct SpinReelPlanTests {
    @Test(arguments: [0.65, 2.0])
    func chosenRuleStopsExactlyInTheCenter(duration: Double) throws {
        let chosen = "The rule selected by the generator"
        let plan = try #require(SpinReelPlan.make(
            from: ["Other A", "Other B", chosen], landingRule: chosen, duration: duration
        ))
        #expect(plan.landingRule == chosen)
        let rowCenter = (Double(plan.landingIndex) + 0.5) * SpinReelPlan.rowHeight
        #expect(rowCenter + plan.landingOffset == SpinReelPlan.windowHeight / 2)
        #expect(plan.landingOffset < 0)
        let reelBottom = Double(plan.rules.count) * SpinReelPlan.rowHeight + plan.landingOffset
        #expect(reelBottom >= SpinReelPlan.windowHeight)
    }

    @Test(arguments: [80.0, 180.0, 260.0, 340.0])
    func responsiveWindowKeepsTheLandingCentered(windowHeight: Double) throws {
        for duration in [0.65, 2.0] {
            let plan = try #require(SpinReelPlan.make(
                from: ["Draw", "Discard"], landingRule: "Discard",
                duration: duration, windowHeight: windowHeight
            ))
            let center = (Double(plan.landingIndex) + 0.5) * SpinReelPlan.rowHeight + plan.landingOffset
            #expect(center == windowHeight / 2)
            #expect(plan.landingRule == "Discard")
            #expect(Double(plan.rules.count) * SpinReelPlan.rowHeight + plan.landingOffset >= windowHeight)
        }
    }

    @Test func displayedLandingAndGeneratorOutcomeMatch() throws {
        let rules = ["Draw", "Draw", "Discard", RuleGenerator.rerollRule]
        for _ in 0..<100 {
            let outcome = try #require(RuleGenerator.pick(from: rules, avoiding: "Draw"))
            let expectedLanding = outcome.didReroll ? RuleGenerator.rerollRule : outcome.rule
            let plan = try #require(SpinReelPlan.make(
                from: rules, landingRule: expectedLanding, duration: 2
            ))
            #expect(plan.landingRule == expectedLanding)
            #expect(outcome.rule == "Discard")
        }
    }

    @Test func singleRuleAndRerollLandingStayAligned() throws {
        let single = try #require(SpinReelPlan.make(from: ["Draw"], landingRule: "Draw", duration: 0.65))
        #expect(single.rules.allSatisfy { $0 == "Draw" })
        let reroll = try #require(SpinReelPlan.make(
            from: ["Draw", RuleGenerator.rerollRule],
            landingRule: RuleGenerator.rerollRule, duration: 2
        ))
        #expect(reroll.landingRule == RuleGenerator.rerollRule)
    }

    @Test func invalidInputsAreSafeAndLongDurationsAreBounded() throws {
        #expect(SpinReelPlan.make(from: [], landingRule: "Draw", duration: 2) == nil)
        #expect(SpinReelPlan.make(from: ["Draw"], landingRule: "Draw", duration: -1) == nil)
        #expect(SpinReelPlan.make(from: ["Draw"], landingRule: "Draw", duration: .infinity) == nil)
        let plan = try #require(SpinReelPlan.make(from: ["Draw"], landingRule: "Draw", duration: 10_000))
        #expect(plan.rules.count < 200)
    }
}
