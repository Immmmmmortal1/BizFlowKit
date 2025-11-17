import UIKit
import BizFlowKit
import ThinkingSDK

final class DemoViewController: UIViewController {
    private enum ThinkingSDKConfig {
        /// Replace with the credentials from your ThinkingData project.
        static let appId = "thinking-demo-app-id"
        static let serverURL = "https://thinkingdata.example.com"
    }

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "BizFlowKit Demo"
        label.font = .boldSystemFont(ofSize: 28)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var initializeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Initialize UMSDK", for: .normal)
        button.configuration = .bordered()
        button.addTarget(self, action: #selector(initializeSDKsTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var initializeThinkingButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Initialize ThinkingSDK", for: .normal)
        button.configuration = .bordered()
        button.addTarget(self, action: #selector(initializeThinkingSDKTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var pipelineButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Run Onboarding Pipeline", for: .normal)
        button.configuration = .borderedProminent()
        button.addTarget(self, action: #selector(runPipelineTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private var logs: [String] = [] {
        didSet {
            tableView.reloadData()
            if logs.isEmpty { return }
            let indexPath = IndexPath(row: logs.count - 1, section: 0)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = "BizFlowKit"
        layoutUI()
    }

    private func layoutUI() {
        view.addSubview(titleLabel)
        view.addSubview(initializeButton)
        view.addSubview(initializeThinkingButton)
        view.addSubview(pipelineButton)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            initializeButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            initializeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            initializeThinkingButton.topAnchor.constraint(equalTo: initializeButton.bottomAnchor, constant: 16),
            initializeThinkingButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            pipelineButton.topAnchor.constraint(equalTo: initializeThinkingButton.bottomAnchor, constant: 16),
            pipelineButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            tableView.topAnchor.constraint(equalTo: pipelineButton.bottomAnchor, constant: 24),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func initializeSDKsTapped() {
        BizFlowKitInitializer.configureUmeng(
            appKey: "6527b30ab2f6fa00ba62c571",
            channel: "App Store",
            enableLog: true
        )

        BizFlowKitInitializer.trackEvent(
            "demo_initialize",
            attributes: ["source": "DemoViewController"]
        )

        appendLog("UMSDK initialized. Check console for BizFlowKit logs.")
    }

    @objc private func runPipelineTapped() {
        Task {
            await runOnboarding()
        }
    }

    @objc private func initializeThinkingSDKTapped() {
        let wasInitialized = BizFlowKitInitializer.isThinkingAnalyticsConfigured
        initializeThinkingSDKIfNeeded()
        if BizFlowKitInitializer.isThinkingAnalyticsConfigured && !wasInitialized {
            appendLog("ThinkingSDK ready. Events will be queued locally.")
        } else if BizFlowKitInitializer.isThinkingAnalyticsConfigured {
            appendLog("ThinkingSDK already initialized.")
        } else {
            appendLog("ThinkingSDK failed to initialize. Check pods and configuration.")
        }
    }

    @MainActor
    private func appendLog(_ message: String) {
        logs.append(message)
    }

    @MainActor
    private func clearLogs() {
        logs = []
    }

    @MainActor
    private func runOnboarding() async {
        clearLogs()

        var context = OnboardingContext()
        let pipeline = OnboardingPipeline().makePipeline()

        do {
            try await pipeline.run(with: &context)
            appendLog("Status: \(String(describing: context.status))")
            appendLog("Metadata: \(context.metadata)")
            trackThinkingAnalytics(event: "demo_pipeline_completed", status: context.status, metadata: context.metadata)
        } catch {
            appendLog("Error: \(error.localizedDescription)")
            trackThinkingAnalytics(event: "demo_pipeline_failed", status: nil, metadata: ["error": error.localizedDescription])
        }
    }

    private func initializeThinkingSDKIfNeeded() {
        BizFlowKitInitializer.configureThinkingAnalytics(
            appId: ThinkingSDKConfig.appId,
            serverURL: ThinkingSDKConfig.serverURL,
            enableLog: true,
            superProperties: [
                "environment": "demo",
                "module": "BizFlowKitExample"
            ],
            initialEvent: (
                name: "demo_thinking_initialized",
                properties: ["timestamp": Date().timeIntervalSince1970]
            )
        )

        if BizFlowKitInitializer.isThinkingAnalyticsConfigured {
            let distinctId = TDAnalytics.getDistinctId()
            appendLog("ThinkingSDK distinctId: \(distinctId)")
        }
    }

    private func trackThinkingAnalytics(
        event: String,
        status: OnboardingContext.Status?,
        metadata: [String: String]
    ) {
        guard BizFlowKitInitializer.isThinkingAnalyticsConfigured else { return }

        var properties: [String: Any] = metadata.reduce(into: [:]) { result, item in
            result["meta_\(item.key)"] = item.value
        }

        if let status {
            properties["status"] = String(describing: status)
        }

        BizFlowKitInitializer.trackThinkingEvent(event, properties: properties)
    }
}

@MainActor
extension DemoViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        logs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "LogCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) ??
            UITableViewCell(style: .default, reuseIdentifier: reuseIdentifier)
        cell.textLabel?.text = logs[indexPath.row]
        cell.textLabel?.numberOfLines = 0
        return cell
    }
}
