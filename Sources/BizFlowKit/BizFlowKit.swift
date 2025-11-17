import Foundation

/// `BizFlowStep` represents a unit of work in the business flow pipeline.
public protocol BizFlowStep {
    associatedtype Input
    associatedtype Output

    /// Executes the step with the given input and produces an output.
    /// Steps should throw errors if they cannot reach a valid state.
    func execute(_ input: Input) async throws -> Output
}

/// Simple wrapper that helps compose multiple steps in a pipeline.
public struct BizFlowPipeline<Context> {
    private let steps: [AnyAsyncStep<Context>]

    public init(steps: [AnyAsyncStep<Context>]) {
        self.steps = steps
    }

    /// Runs each step in order, mutating the shared context.
    @discardableResult
    public func run(with context: inout Context) async throws -> Context {
        for step in steps {
            try await step.execute(&context)
        }
        return context
    }
}

/// Type erasure for async steps that mutate the pipeline context in-place.
public struct AnyAsyncStep<Context> {
    private let runClosure: (inout Context) async throws -> Void

    public init<S: AsyncContextStep>(_ step: S) where S.Context == Context {
        self.runClosure = step.execute
    }

    public init(_ runClosure: @escaping (inout Context) async throws -> Void) {
        self.runClosure = runClosure
    }

    public func execute(_ context: inout Context) async throws {
        try await runClosure(&context)
    }
}

/// Protocol for steps that mutate a shared context in-place.
public protocol AsyncContextStep {
    associatedtype Context

    func execute(_ context: inout Context) async throws
}

/// Default implementation for synchronous steps to be used inside async pipelines.
public struct SyncContextStep<Context>: AsyncContextStep {
    private let body: (inout Context) throws -> Void

    public init(_ body: @escaping (inout Context) throws -> Void) {
        self.body = body
    }

    public func execute(_ context: inout Context) async throws {
        try body(&context)
    }
}

/// Example business flow context that tracks a user onboarding process.
public struct OnboardingContext: Sendable {
    public enum Status: Sendable {
        case initiated
        case collectingProfile
        case awaitingApproval
        case completed
    }

    public var status: Status
    public var metadata: [String: String]

    public init(status: Status = .initiated, metadata: [String: String] = [:]) {
        self.status = status
        self.metadata = metadata
    }
}

/// Demonstrates how to build a reusable pipeline with custom steps.
public struct OnboardingPipeline {
    public init() {}

    public func makePipeline() -> BizFlowPipeline<OnboardingContext> {
        BizFlowPipeline(
            steps: [
                AnyAsyncStep(SyncContextStep { context in
                    context.status = .collectingProfile
                    context.metadata["profile"] = "basic"
                }),
                AnyAsyncStep { context in
                    try await Task.sleep(nanoseconds: 100_000_000) // simulate request
                    context.status = .awaitingApproval
                },
                AnyAsyncStep(SyncContextStep { context in
                    context.status = .completed
                })
            ]
        )
    }
}
