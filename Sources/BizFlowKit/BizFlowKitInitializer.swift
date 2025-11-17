import Foundation
import UMCommon
import UMPush

#if canImport(AdjustSdk)
import AdjustSdk
#endif

#if canImport(ThinkingSDK)
import ThinkingSDK
#endif

#if canImport(ThinkingSDK)
public typealias ThinkingAnalyticsConfigurator = (TDConfig) -> Void
#else
public typealias ThinkingAnalyticsConfigurator = (AnyObject) -> Void
#endif

#if canImport(UIKit)
import UIKit
#endif

#if canImport(UserNotifications)
import UserNotifications
#endif

#if canImport(AppTrackingTransparency)
import AppTrackingTransparency
#endif

/// 提供统一的入口在宿主 App 中初始化友盟能力。
public enum BizFlowKitInitializer {
    private static var isThinkingSDKConfiguredInternal = false
    private static var isAdjustConfiguredInternal = false

    /// Indicates whether ThinkingSDK has been configured by the initializer.
    public private(set) static var isThinkingAnalyticsConfigured: Bool {
        get { isThinkingSDKConfiguredInternal }
        set { isThinkingSDKConfiguredInternal = newValue }
    }

    /// 初始化友盟基础组件并启用常见的 APM 监控项。
    /// - Parameters:
    ///   - appKey: 友盟后台申请的 AppKey。
    ///   - channel: 渠道标识，默认 `App Store`。
    ///   - enableLog: 是否打印 SDK 调试日志。
    ///   - apmConfigurator: 如需自定义 `UMAPMConfig`，可在此闭包中修改。
    public static func configureUmeng(
        appKey: String,
        channel: String = "App Store",
        enableLog: Bool = false,
        apmConfigurator: ((NSObject) -> Void)? = nil
    ) {
        UMConfigure.setLogEnabled(enableLog)
        UMConfigure.initWithAppkey(appKey, channel: channel)
        UMConfigure.setEncryptEnabled(true)

        configureAPM(apmConfigurator: apmConfigurator)
    }

#if canImport(UIKit) && canImport(UserNotifications)
    /// 注册友盟推送能力，需要在 `application(_:didFinishLaunchingWithOptions:)` 中调用。
    /// - Parameters:
    ///   - launchOptions: 启动参数。
    ///   - injectEntity: 可选闭包，用于自定义 `UMessageRegisterEntity` 的授权选项。
    ///   - completion: 推送注册完成回调。
    public static func registerPush(
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?,
        injectEntity: ((UMessageRegisterEntity) -> Void)? = nil,
        completion: ((Bool, Error?) -> Void)? = nil
    ) {
        let entity = UMessageRegisterEntity()
        entity.types = Int(
            UNAuthorizationOptions.badge.rawValue |
                UNAuthorizationOptions.sound.rawValue |
                UNAuthorizationOptions.alert.rawValue
        )
        injectEntity?(entity)

        UMessage.registerForRemoteNotifications(
            launchOptions: launchOptions,
            entity: entity
        ) { granted, error in
            DispatchQueue.main.async {
                completion?(granted, error)
            }
        }
    }

    /// 将系统回调的 deviceToken 上报给友盟推送。
    public static func registerDeviceToken(_ deviceToken: Data) {
        UMessage.registerDeviceToken(deviceToken)
    }

    /// 处理友盟推送的自定义消息。
    public static func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) {
        UMessage.didReceiveRemoteNotification(userInfo)
    }
#endif

    /// 友盟埋点事件上报的简单封装。
    public static func trackEvent(_ name: String, attributes: [String: Any]? = nil) {
        if let attributes = attributes {
            MobClick.event(name, attributes: attributes)
        } else {
            MobClick.event(name)
        }
    }

    static func configureAPM(apmConfigurator: ((NSObject) -> Void)?) {
        guard let configClass = NSClassFromString("UMAPMConfig") as? NSObject.Type else {
            log("[Initializer] UMAPMConfig not found.")
            return
        }

        guard let config = configClass
            .perform(NSSelectorFromString("defaultConfig"))?
            .takeUnretainedValue() as? NSObject
        else {
            log("[Initializer] Failed to create UMAPMConfig.")
            return
        }

        config.setValue(true, forKey: "crashAndBlockMonitorEnable")
        config.setValue(true, forKey: "launchMonitorEnable")
        config.setValue(true, forKey: "memMonitorEnable")
        config.setValue(true, forKey: "oomMonitorEnable")
        config.setValue(true, forKey: "networkEnable")
        config.setValue(true, forKey: "pageMonitorEnable")

        apmConfigurator?(config)

        if let crashConfigureClass = NSClassFromString("UMCrashConfigure") {
            _ = (crashConfigureClass as AnyObject)
                .perform(NSSelectorFromString("setAPMConfig:"), with: config)
        }
    }

    static func log(_ message: String) {
        print("[BizFlowKit][UMSDK] \(message)")
    }
}

#if canImport(AdjustSdk)
extension BizFlowKitInitializer {
    public private(set) static var isAdjustConfigured: Bool {
        get { isAdjustConfiguredInternal }
        set { isAdjustConfiguredInternal = newValue }
    }
}

extension BizFlowKitInitializer {
    public typealias AdjustConfigurator = (ADJConfig) -> Void
    public typealias AdjustAttributionHandler = (_ attribution: ADJAttribution, _ isFromCache: Bool) -> Void

    /// 初始化 Adjust SDK 并配置常用参数。
    /// - Parameters:
    ///   - appToken: Adjust 后台的 App Token。
    ///   - environment: 运行环境，默认为正式环境 `ADJEnvironmentProduction`。
    ///   - logLevel: 日志级别，默认 `.info`。
    ///   - allowBackgroundTracking: 是否允许后台上报。
    ///   - allowiAdInfoReading: 是否允许读取 iAd 信息。
    ///   - allowAdServicesInfoReading: 是否允许读取 Apple AdServices 信息。
    ///   - launchDeferredDeeplink: 是否自动拉起延迟深度链接。
    ///   - externalDeviceId: 可选的外部设备 ID。
    ///   - globalPartnerParameters: 需要注入的全局伙伴参数。
    ///   - configure: 可对 `ADJConfig` 做进一步自定义。
    ///   - attributionHandler: 初始化完成后回调最新归因信息。
    public static func configureAdjust(
        appToken: String,
        environment: String = ADJEnvironmentProduction,
        logLevel: ADJLogLevel = .info,
        allowBackgroundTracking: Bool = true,
        allowiAdInfoReading: Bool = true,
        allowAdServicesInfoReading: Bool = true,
        launchDeferredDeeplink: Bool = false,
        externalDeviceId: String? = nil,
        globalPartnerParameters: [String: String]? = nil,
        configure: AdjustConfigurator? = nil,
        attributionHandler: AdjustAttributionHandler? = nil
    ) {
        guard !isAdjustConfigured else {
            log("[Adjust] Already configured.")
            return
        }

        guard let config = ADJConfig(appToken: appToken, environment: environment) else {
            log("[Adjust] Failed to create ADJConfig.")
            return
        }

        config.logLevel = logLevel
        config.sendInBackground = allowBackgroundTracking
        config.allowiAdInfoReading = allowiAdInfoReading
        config.allowAdServicesInfoReading = allowAdServicesInfoReading
        config.launchDeferredDeeplink = launchDeferredDeeplink
        if let externalDeviceId {
            config.externalDeviceId = externalDeviceId
        }

        configure?(config)
        Adjust.initSdk(config)

        globalPartnerParameters?.forEach { key, value in
            Adjust.addGlobalPartnerParameter(value, forKey: key)
        }

        if let attributionHandler {
            Adjust.attribution { attribution in
                guard let attribution else { return }
                DispatchQueue.main.async {
                    attributionHandler(attribution, false)
                }
            }
        }

        isAdjustConfigured = true
        log("[Adjust] Initialized with appToken: \(appToken).")
    }

    /// 上报 Adjust 事件。
    /// - Parameters:
    ///   - token: Adjust 后台配置的事件 token。
    ///   - revenue: 可选的付费金额。
    ///   - currency: 付费货币代码，必须与 revenue 同时存在。
    ///   - callbackParameters: 事件级别的回调参数。
    ///   - partnerParameters: 事件级别的伙伴参数。
    public static func trackAdjustEvent(
        token: String,
        revenue: NSDecimalNumber? = nil,
        currency: String? = nil,
        callbackParameters: [String: String]? = nil,
        partnerParameters: [String: String]? = nil
    ) {
        guard isAdjustConfigured else {
            log("[Adjust] track called before initialization.")
            return
        }

        guard let event = ADJEvent(eventToken: token) else {
            log("[Adjust] Failed to create event for token: \(token).")
            return
        }

        if let revenue, let currency {
            event.setRevenue(revenue.doubleValue, currency: currency)
        }

        callbackParameters?.forEach { key, value in
            event.addCallbackParameter(value, forKey: key)
        }

        partnerParameters?.forEach { key, value in
            event.addPartnerParameter(value, forKey: key)
        }

        Adjust.trackEvent(event)
    }

#if canImport(AppTrackingTransparency)
    /// 请求 App Tracking Transparency 授权，可在调用 `configureAdjust` 之后触发。
    /// - Parameter completion: 授权结果回调。
    public static func requestTrackingAuthorization(completion: ((ATTrackingManager.AuthorizationStatus) -> Void)? = nil) {
        guard #available(iOS 14, *) else {
            completion?(.authorized)
            return
        }
        ATTrackingManager.requestTrackingAuthorization { status in
            DispatchQueue.main.async {
                completion?(status)
            }
        }
    }
#endif
}
#endif

#if canImport(ThinkingSDK)
extension BizFlowKitInitializer {
    /// 快速初始化 ThinkingSDK，保持与友盟相同的调用风格。
    /// - Parameters:
    ///   - appId: ThinkingSDK 项目的 AppId。
    ///   - serverURL: 数据上报服务端地址。
    ///   - enableLog: 是否开启 SDK 内部日志。
    ///   - enableAutoTrack: 是否启用全量自动埋点。
    ///   - superProperties: 需要预先设置的公共事件属性。
    ///   - distinctId: 自定义 distinctId，不传则默认使用 deviceId。
    ///   - configure: 可自定义 TDConfig，例如设置调试模式、加密等。
    ///   - initialEvent: 初始化成功后立即上报的测试事件。
    public static func configureThinkingAnalytics(
        appId: String,
        serverURL: String,
        enableLog: Bool = false,
        enableAutoTrack: Bool = true,
        superProperties: [String: Any]? = nil,
        distinctId: String? = nil,
        configure: ThinkingAnalyticsConfigurator? = nil,
        initialEvent: (name: String, properties: [String: Any])? = nil
    ) {
        guard !isThinkingAnalyticsConfigured else {
            log("[ThinkingAnalytics] Already configured.")
            return
        }

        TDAnalytics.enableLog(enableLog)
        TDAnalytics.start(withAppId: appId, serverUrl: serverURL)

        let config = TDConfig()
        config.appid = appId
        config.serverUrl = serverURL
        configure?(config)
        TDAnalytics.start(with: config)

        if enableAutoTrack {
            let allEvents = TDAutoTrackEventType(rawValue: ThinkingAnalyticsConstants.autoTrackAllMask)
            TDAnalytics.enableAutoTrack(allEvents)
        }

        if let superProperties, !superProperties.isEmpty {
            TDAnalytics.setSuperProperties(superProperties)
        }

        let resolvedDistinctId = distinctId ?? TDAnalytics.getDeviceId()
        TDAnalytics.setDistinctId(resolvedDistinctId)

        if let initialEvent {
            TDAnalytics.track(initialEvent.name, properties: initialEvent.properties)
        }

        isThinkingAnalyticsConfigured = true
        log("[ThinkingAnalytics] Initialized with appId: \(appId), distinctId: \(resolvedDistinctId).")
    }

    /// ThinkingSDK 简易事件打点封装。
    /// - Parameters:
    ///   - name: 事件名称。
    ///   - properties: 可选的事件属性。
    public static func trackThinkingEvent(_ name: String, properties: [String: Any]? = nil) {
        guard isThinkingAnalyticsConfigured else {
            log("[ThinkingAnalytics] track called before initialization.")
            return
        }

        if let properties, !properties.isEmpty {
            TDAnalytics.track(name, properties: properties)
        } else {
            TDAnalytics.track(name)
        }
    }
}
#else
extension BizFlowKitInitializer {
    public static func configureThinkingAnalytics(
        appId: String,
        serverURL: String,
        enableLog: Bool = false,
        enableAutoTrack: Bool = true,
        superProperties: [String: Any]? = nil,
        distinctId: String? = nil,
        configure: ThinkingAnalyticsConfigurator? = nil,
        initialEvent: (name: String, properties: [String: Any])? = nil
    ) {
        log("[ThinkingAnalytics] Module not linked. Skipping initialization.")
    }

    public static func trackThinkingEvent(_ name: String, properties: [String: Any]? = nil) {
        log("[ThinkingAnalytics] Module not linked. Skip track for \(name).")
    }
}
#endif

private enum ThinkingAnalyticsConstants {
    static let autoTrackAllMask: UInt = 0x3F
}
