# ColleagueDemo

用于模拟同事在独立项目中通过 CocoaPods 引入 `BizFlowKit` 的流程。

## 使用步骤

1. 在该目录执行 `pod install`（首次已经完成，可再次执行验证缓存）。
2. 打开生成的 `ColleagueDemo.xcworkspace`。
3. 在 `App/AppDelegate.swift` 中查看如何调用 `BizFlowKitInitializer` 接口，实现友盟、Adjust 等初始化。
4. 运行 `ColleagueDemo` 目标体验示例页面：
   - `Initialize UMSDK`：初始化友盟基础组件及 APM。
   - `Initialize ThinkingSDK`：可选埋点 SDK，一旦宿主项目也集成即可使用。
   - `Initialize Adjust`：调用新增的 Adjust 封装。
   - `Run Onboarding Pipeline`：执行业务流程并观察日志。
   - `Thinking distinctId` 日志来自 `BizFlowKitInitializer.thinkingDistinctId()`，无需直接引用第三方 SDK。

> Podfile 通过 Git tag `0.1.2` 指向刚发布的版本，如后续有新版本只需更新 tag 或使用 `~> 最新版本`。
