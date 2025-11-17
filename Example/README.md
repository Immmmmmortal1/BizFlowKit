## Example App Setup

1. 打开本目录的 `Podfile` 可见目标已经集成 `pod 'BizFlowKit', :path => '..'`（开发路径依赖）。
2. 在终端执行：

   ```bash
   pod install
   ```

3. 打开生成的 `BizFlowKitExample.xcworkspace`，此时 CocoaPods 会将 BizFlowKit 以 Development Pods 形式挂载。
4. 运行示例工程，点击 `Initialize UMSDK` 可完成友盟初始化；点击 `Initialize ThinkingSDK` 按钮体验 ThinkingSDK 的统一封装，随后通过 `Run Onboarding Pipeline` 观察业务流程日志与本地事件上报。

> 示例中 `ThinkingSDKConfig` 里的 `appId/serverURL` 仅为占位符，集成真实项目时请替换为控制台提供的配置。
>
> ThinkingSDK 初始化同样通过 `BizFlowKitInitializer.configureThinkingAnalytics` 封装调用，与友盟接口保持一致，并在示例中展示自动埋点与 distinctId 的读取。

> 注意：初次安装 Pod 会自动将 BizFlowKit 作为本地路径依赖，你可以直接在组件源码与示例 App 之间进行调试。

> 示例使用的 `ContentView` 位于 `Example/App/ContentView.swift`，在 Xcode 中编辑即可同步更新。
