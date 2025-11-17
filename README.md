# BizFlowKit

BizFlowKit 是一个示例 CocoaPods 组件工程，用于在公司内部沉淀业务编排能力，并通过私有或公开 CocoaPods 仓库发布给同事一键集成。

## 工程结构

- `BizFlowKit.podspec`：Pod 配置文件，集中声明版本、源码路径、Swift 版本和依赖。
- `Sources/BizFlowKit`：组件主体源码。当前提供一个示例的业务流协调器与节点协议。
- `Tests/BizFlowKitTests`：使用 `XCTest` 的单元测试示例。
- `Example`：示例应用模版与 Podfile，可用于验证组件功能。

## 给同事的集成指引

```ruby
pod 'BizFlowKit', '~> 0.1.1'
```

1. 在目标项目的 `Podfile` 中加入上述依赖，并执行 `pod install`。
2. 在使用处 `import BizFlowKit`，即可访问管线、节点等公共接口。
3. 后续版本升级时，只需同步更新 `Podfile` 版本号并重新安装即可。

## SDK 初始化示例

以下示例展示了如何在 AppDelegate 中初始化 BizFlowKit 当前内置的友盟能力，并在需要时接入 ThinkingSDK：

```swift
import UIKit
import BizFlowKit
import AppTrackingTransparency

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        BizFlowKitInitializer.configureUmeng(
            appKey: "<UMeng_AppKey>",
            channel: "App Store",
            enableLog: true
        )

        BizFlowKitInitializer.registerPush(
            launchOptions: launchOptions,
            injectEntity: { entity in
                entity.types = Int(
                    UNAuthorizationOptions.alert.rawValue |
                    UNAuthorizationOptions.badge.rawValue |
                    UNAuthorizationOptions.sound.rawValue
                )
            },
            completion: { granted, error in
                print("Push permission: \(granted), error: \(String(describing: error))")
            }
        )

        #if canImport(ThinkingSDK)
        BizFlowKitInitializer.configureThinkingAnalytics(
            appId: "<Thinking_AppId>",
            serverURL: "<Thinking_Server_URL>",
            enableLog: true,
            superProperties: ["channel": "App Store"]
        )
        #endif

        #if canImport(Adjust)
        BizFlowKitInitializer.configureAdjust(
            appToken: "<Adjust_AppToken>",
            globalPartnerParameters: ["channel": "App Store"]
        )

        BizFlowKitInitializer.requestTrackingAuthorization { status in
            print("ATT status: \(status.rawValue)")
        }
        #endif

        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        BizFlowKitInitializer.registerDeviceToken(deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Push registration failed: \(error)")
    }
}
```

埋点上报可通过以下方法触发：

```swift
BizFlowKitInitializer.trackEvent("onboarding_complete", attributes: ["step": 3])

#if canImport(ThinkingSDK)
BizFlowKitInitializer.trackThinkingEvent("purchase", properties: ["amount": 99.0])
#endif

#if canImport(Adjust)
BizFlowKitInitializer.trackAdjustEvent(
    token: "<EVENT_TOKEN>",
    revenue: 9.99,
    currency: "USD",
    partnerParameters: ["source": "in_app"]
)
#endif
```

> 当前 Podspec 默认集成 `UMCommon`、`UMDevice`、`UMAPM`、`UMABTest`、`UMPush` 以及 `Adjust (含 AdjustGoogleOdm)`、`GoogleAdsOnDeviceConversion` 等组件；ThinkingSDK 为可选依赖，只有宿主项目自行引入后，以上初始化才会执行真实逻辑。

## 第三方依赖扩展

BizFlowKit 默认不预置任何第三方 SDK，方便在不同业务场景下按需组合。若需要集成额外能力，可在 `BizFlowKit.podspec` 中通过 `s.dependency` 增加依赖，并在组件源码里实现对应的封装。

## 示例能力

示例 App 演示了基于 `BizFlowPipeline` 的入门流程，并提供 `BizFlowKitInitializer` 对友盟 SDK 进行统一初始化。运行后：

- 点击 `Initialize UMSDK` 完成友盟基础组件配置。
- 点击 `Run Onboarding Pipeline` 查看流程节点执行情况与上下文日志。

你可以在此基础上扩展更多节点，或接入自定义监控与埋点方案。

## 快速开始

1. 安装依赖

   ```bash
   cd Example
   pod install
   ```

2. 打开 `BizFlowKitExample.xcworkspace`，此 workspace 会自动引入 `Pods/Pods.xcodeproj` 与 `BizFlowKit` Development Pod。

3. 在 `Sources/BizFlowKit` 中添加或修改业务流程相关的 Swift 代码；在 `Tests/BizFlowKitTests` 里同步补充单元测试。

## Podspec 配置要点

- `s.version`：更新版本号后，才可以再次发布到 CocoaPods。
- `s.source`：发布前需要将 Git 仓库地址与 tag 配置到位。
- `s.swift_versions`：默认为 `5.7`，可按需扩展支持的 Swift 版本。
- `s.ios.deployment_target`：当前设定 iOS 15.0 及以上。

更多字段说明可参考 [CocoaPods 官方文档](https://guides.cocoapods.org/syntax/podspec.html)。

## 本地验证

- `pod lib lint BizFlowKit.podspec`：检查 Podspec 是否符合规范。
- `pod spec lint BizFlowKit.podspec`：与上类似，但会使用远端仓库地址进行校验（需在网络与认证允许情况下）。

## 发布流程示例

1. 推送源码到 Git 仓库并打 tag（例如 `0.1.1`）。
2. 将 `s.source` 中的地址与 tag 更新为实际值并提交。
3. 执行 `pod spec lint` 确认无误。
4. 根据公司流程，将 Podspec 推送到内部 Specs 仓库或官方 CocoaPods Trunk。

## 后续扩展建议

- 根据业务拆解更多流程节点类型与插件。
- 在 `Example` 中完善一个真实业务场景 Demo，帮助团队理解用法。
- 配置 CI 进行自动化测试与 `pod lib lint` 检查，保证发布质量。
