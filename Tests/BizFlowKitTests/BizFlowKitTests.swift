import XCTest
@testable import BizFlowKit

final class BizFlowKitTests: XCTestCase {
    func testOnboardingPipelineReachesCompleted() async throws {
        var context = OnboardingContext()
        let pipeline = OnboardingPipeline().makePipeline()

        try await pipeline.run(with: &context)

        XCTAssertEqual(context.status, .completed)
        XCTAssertEqual(context.metadata["profile"], "basic")
    }
}
