//
//  SNSNotificationManager.swift
//  SNSNotificationSDK
//
//  Created by Awaken Mobile on 15/4/2025.
//

//sns video playing on app launch all working

//import UIKit
//import UserNotifications
//import CoreLocation
//import AVKit
//
//// MARK: - Public Protocol
//
//public protocol SNSNotificationDelegate: AnyObject {
//    func didRegisterDeviceToken(_ token: String)
//    func didReceiveNotification(_ notification: UNNotification)
//    func registrationFailed(error: SNSError)
//    func willPresentVideo(url: URL, at time: Double)
//    func didCompleteVideoPresentation()
//}
//
//public extension SNSNotificationDelegate {
//    func willPresentVideo(url: URL, at time: Double) {}
//    func didCompleteVideoPresentation() {}
//}
//
//// MARK: - Main Manager
//
//public final class SNSNotificationManager: NSObject, AVPlayerViewControllerDelegate {
//
//    public static let shared = SNSNotificationManager()
//    public weak var delegate: SNSNotificationDelegate?
//
//    private var hashKey: String?
//    private var deviceToken: String?
//    private var currentVideoController: AVPlayerViewController?
//
//    private struct StorageKeys {
//        static let videoState = "sns_pending_video_state"
//    }
//
//    // MARK: - Setup
//
//    public static func quickSetup(
//        hashKey: String,
//        delegate: SNSNotificationDelegate? = nil,
//        enableLocationUpdates: Bool = true,
//        autoRegisterNotifications: Bool = true
//    ) {
//        let manager = SNSNotificationManager.shared
//        manager.delegate = delegate
//        manager.configure(hashKey: hashKey)
//
//        if autoRegisterNotifications {
//            manager.requestAuthorization { granted, _ in
//                if granted {
//                    manager.registerForNotifications()
//                }
//            }
//        }
//
//        UNUserNotificationCenter.current().delegate = manager
//
//        NotificationCenter.default.addObserver(
//            manager,
//            selector: #selector(manager.appDidBecomeActive),
//            name: UIApplication.didBecomeActiveNotification,
//            object: nil
//        )
//
//        if enableLocationUpdates {
//            SNSLocationManager.shared.startLocationUpdates()
//        }
//    }
//
//    private func configure(hashKey: String) {
//        self.hashKey = hashKey
//    }
//
//    public func handleAppLaunch(with launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
//        print("🚀 SNS: App launched")
//        if let userInfo = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
//            handleNotificationPayload(convertUserInfo(userInfo))
//        }
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            self.checkAndRestoreVideo()
//        }
//    }
//
//    @objc private func appDidBecomeActive() {
//        print("🔄 SNS: App became active")
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//            self.checkAndRestoreVideo()
//        }
//    }
//
//    // MARK: - Video Playback
//
//    private func checkAndRestoreVideo(retryCount: Int = 3) {
//        print("🎬 SNS: Checking for pending video (attempt \(4 - retryCount))")
//
//        guard let defaults = UserDefaults(suiteName: SNSNotificationConstants.appGroupIdentifier) else {
//            print("❌ SNS: App group UserDefaults not accessible")
//            return
//        }
//
//        guard let data = defaults.data(forKey: StorageKeys.videoState),
//              let videoState = try? JSONDecoder().decode(SNSVideoState.self, from: data) else {
//
//            if retryCount > 0 {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                    self.checkAndRestoreVideo(retryCount: retryCount - 1)
//                }
//            } else {
//                print("📭 SNS: No saved video state found")
//            }
//
//            return
//        }
//
//        defaults.removeObject(forKey: StorageKeys.videoState)
//        presentVideo(from: videoState)
//    }
//
//    //creating for image
////    private func checkAndRestoreImage() {
////        guard let defaults = UserDefaults(suiteName: SNSNotificationConstants.appGroupIdentifier),
////              let data = defaults.data(forKey: "sns_pending_image_state"),
////              let urlString = (try? JSONDecoder().decode(SNSImageState.self, from: data))?.url,
////              let url = URL(string: urlString),
////              let topVC = getTopViewController()
////        else { return }
////
////        defaults.removeObject(forKey: "sns_pending_image_state")
////
////        let imageVC = SNSImageFullscreenViewController(imageURL: url)
////        topVC.present(imageVC, animated: true)
////    }
////end image state
//    
//    
//    private func presentVideo(from state: SNSVideoState) {
//        guard let url = URL(string: state.url) else {
//            print("❌ SNS: Invalid video URL")
//            return
//        }
//
//        guard let topVC = getTopViewController() else {
//            print("❌ SNS: Unable to find top view controller")
//            return
//        }
//
//        // Make sure prior controller (if any) is gone
//        if let existing = currentVideoController {
//            existing.dismiss(animated: false)
//            currentVideoController = nil
//        }
//
//        let player = AVPlayer(url: url)
//        let controller = AVPlayerViewController()
//        controller.player = player
//        controller.modalPresentationStyle = .fullScreen
//        controller.delegate = self
//
//        currentVideoController = controller
//
//        print("▶️ SNS: Presenting video from \(state.currentTime)s")
//
//        delegate?.willPresentVideo(url: url, at: state.currentTime)
//
//        topVC.present(controller, animated: true) { [weak self] in
//            let seekTime = CMTime(seconds: state.currentTime, preferredTimescale: 600)
//
//            player.seek(to: seekTime) { [weak self] success in
//                if success && state.isPlaying {
//                    player.play()
//                    print("✅ SNS: Video playback started")
//                } else {
//                    print("⚠️ SNS: Seek or playback failed")
//                }
//            }
//        }
//    }
//
//    // MARK: - AVPlayerViewControllerDelegate
//
//    public func playerViewControllerWillEndPlayback(_ playerViewController: AVPlayerViewController) {
//        print("👋 SNS: Video dismissed")
//        currentVideoController = nil
//        delegate?.didCompleteVideoPresentation()
//    }
//
//    // MARK: - Notification Payload Handler
//
//    private func handleNotificationPayload(_ userInfo: [String: Any]) {
//        print("📨 SNS: handleNotificationPayload called")
//
//        guard let url = userInfo["video_url"] as? String else {
//            print("❌ SNS: No video_url found in payload")
//            return
//        }
//
//        let time = userInfo["video_current_time"] as? Double ?? 0
//        let isPlaying = userInfo["video_is_playing"] as? Bool ?? true
//
//        let state = SNSVideoState(url: url, currentTime: time, isPlaying: isPlaying)
//        saveVideoState(state)
//    }
//
//    private func saveVideoState(_ state: SNSVideoState) {
//        guard let data = try? JSONEncoder().encode(state),
//              let defaults = UserDefaults(suiteName: SNSNotificationConstants.appGroupIdentifier) else {
//            print("❌ SNS: Failed to encode or access storage")
//            return
//        }
//
//        defaults.set(data, forKey: StorageKeys.videoState)
//        defaults.synchronize()
//        print("✅ SNS: Video state saved")
//    }
//
//    // MARK: - User Notifications
//
//    public func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
//        let options: UNAuthorizationOptions = [.alert, .badge, .sound, .criticalAlert]
//        UNUserNotificationCenter.current().requestAuthorization(options: options, completionHandler: completion)
//    }
//
//    public func registerForNotifications() {
//        DispatchQueue.main.async {
//            UIApplication.shared.registerForRemoteNotifications()
//        }
//    }
//
//    public func setDeviceToken(_ deviceToken: Data) {
//        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
//        self.deviceToken = token
//        print("✅ SNS: Registered device token: \(token)")
//        delegate?.didRegisterDeviceToken(token)
//    }
//
//    // MARK: - Location Updates
//
//    public func updateDeviceLocation(_ coordinate: CLLocationCoordinate2D) {
//        print("📍 SNS: updateDeviceLocation lat:\(coordinate.latitude), lon:\(coordinate.longitude)")
//        // Hook to send to backend, if needed
//    }
//
//    // MARK: - Utilities
//
//    private func getTopViewController() -> UIViewController? {
//        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//              let window = windowScene.windows.first(where: { $0.isKeyWindow }),
//              let rootVC = window.rootViewController else {
//            return nil
//        }
//
//        var topVC = rootVC
//        while let presented = topVC.presentedViewController {
//            topVC = presented
//        }
//
//        return topVC
//    }
//
//    private func convertUserInfo(_ userInfo: [AnyHashable: Any]) -> [String: Any] {
//        var result = [String: Any]()
//        for (key, value) in userInfo {
//            if let keyString = key as? String {
//                result[keyString] = value
//            }
//        }
//        return result
//    }
//}
//
//// MARK: - Push Notification Delegate
//
//extension SNSNotificationManager: UNUserNotificationCenterDelegate {
//    public func userNotificationCenter(_ center: UNUserNotificationCenter,
//                                       willPresent notification: UNNotification,
//                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
//        delegate?.didReceiveNotification(notification)
//        completionHandler([.banner, .sound])
//    }
//
//    public func userNotificationCenter(_ center: UNUserNotificationCenter,
//                                       didReceive response: UNNotificationResponse,
//                                       withCompletionHandler completionHandler: @escaping () -> Void) {
//        print("🔔 SNS: Notification tapped")
//
//        let payload = convertUserInfo(response.notification.request.content.userInfo)
//        handleNotificationPayload(payload)
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
//            self.checkAndRestoreVideo()
//        }
//
//        completionHandler()
//    }
//}
//
//// MARK: - SDK Error Enum
//
//public enum SNSError: Error {
//    case missingHashKey
//    case serverError(String)
//    case networkError(Error)
//    case registrationError(Error)
//
//    public var localizedDescription: String {
//        switch self {
//        case .missingHashKey: return "Missing hash key"
//        case .serverError(let msg): return msg
//        case .networkError(let err): return err.localizedDescription
//        case .registrationError(let err): return err.localizedDescription
//        }
//    }
//}
//



//image and video both working
//import UIKit
//import UserNotifications
//import CoreLocation
//import AVKit
//
//// MARK: - Public Protocol
//
//public protocol SNSNotificationDelegate: AnyObject {
//    func didRegisterDeviceToken(_ token: String)
//    func didReceiveNotification(_ notification: UNNotification)
//    func registrationFailed(error: SNSError)
//    func willPresentVideo(url: URL, at time: Double)
//    func didCompleteVideoPresentation()
//}
//
//// ✅ Make default implementations optional
//public extension SNSNotificationDelegate {
//    func willPresentVideo(url: URL, at time: Double) {}
//    func didCompleteVideoPresentation() {}
//}
//
//// MARK: - Main SDK Manager
//
//public final class SNSNotificationManager: NSObject, AVPlayerViewControllerDelegate {
//    
//    public static let shared = SNSNotificationManager()
//    public weak var delegate: SNSNotificationDelegate?
//    
//    private var hashKey: String?
//    private var deviceToken: String?
//    private var currentVideoController: AVPlayerViewController?
//    
//    private struct StorageKeys {
//        static let videoState = "sns_pending_video_state"
//        static let imageState = "sns_pending_image_state"
//    }
//
//    // MARK: Setup Entrypoint
//
//    public static func quickSetup(
//        hashKey: String,
//        delegate: SNSNotificationDelegate? = nil,
//        enableLocationUpdates: Bool = true,
//        autoRegisterNotifications: Bool = true
//    ) {
//        let manager = SNSNotificationManager.shared
//        manager.delegate = delegate
//        manager.configure(hashKey: hashKey)
//
//        if autoRegisterNotifications {
//            manager.requestAuthorization { granted, error in
//                if granted {
//                    manager.registerForNotifications()
//                } else if let error = error {
//                    delegate?.registrationFailed(error: .registrationError(error))
//                }
//            }
//        }
//
//        UNUserNotificationCenter.current().delegate = manager
//
//        NotificationCenter.default.addObserver(
//            manager,
//            selector: #selector(manager.appDidBecomeActive),
//            name: UIApplication.didBecomeActiveNotification,
//            object: nil
//        )
//
//        if enableLocationUpdates {
//            SNSLocationManager.shared.startLocationUpdates()
//        }
//    }
//
//    private func configure(hashKey: String) {
//        self.hashKey = hashKey
//    }
//
//    // MARK: App Lifecycle Handling
//
//    public func handleAppLaunch(with launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
//        print("🚀 SNS: App launched")
//
//        if let userInfo = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
//            handleNotificationPayload(convertUserInfo(userInfo))
//        }
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            self.checkAndRestoreVideo(retryCount: 3) { videoRestored in
//                if !videoRestored {
//                    self.checkAndRestoreImage(retryCount: 3)
//                }
//            }
//        }
//    }
//
//    @objc private func appDidBecomeActive() {
//        print("🔄 SNS: App became active")
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//            self.checkAndRestoreVideo(retryCount: 3) { videoRestored in
//                if !videoRestored {
//                    self.checkAndRestoreImage(retryCount: 3)
//                }
//            }
//        }
//    }
//
//    // MARK: - Video State Restore
//
//    private func checkAndRestoreVideo(retryCount: Int = 3, completion: ((Bool) -> Void)? = nil) {
//        print("🎬 SNS: Checking for pending video (attempt \(4 - retryCount))")
//
//        guard let defaults = UserDefaults(suiteName: SNSNotificationConstants.appGroupIdentifier) else {
//            print("❌ SNS: App group UserDefaults not accessible")
//            completion?(false)
//            return
//        }
//
//        guard let data = defaults.data(forKey: StorageKeys.videoState),
//              let videoState = try? JSONDecoder().decode(SNSVideoState.self, from: data) else {
//
//            if retryCount > 0 {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                    self.checkAndRestoreVideo(retryCount: retryCount - 1, completion: completion)
//                }
//            } else {
//                print("📭 SNS: No saved video state found")
//                completion?(false)
//            }
//
//            return
//        }
//
//        defaults.removeObject(forKey: StorageKeys.videoState)
//        presentVideo(from: videoState)
//        completion?(true)
//    }
//
//    private func presentVideo(from state: SNSVideoState) {
//        guard let url = URL(string: state.url) else {
//            print("❌ SNS: Invalid video URL")
//            return
//        }
//
//        guard let topVC = getTopViewController() else {
//            print("❌ SNS: Unable to find top view controller")
//            return
//        }
//
//        if let existing = currentVideoController {
//            existing.dismiss(animated: false)
//        }
//
//        let player = AVPlayer(url: url)
//        let controller = AVPlayerViewController()
//        controller.player = player
//        controller.modalPresentationStyle = .fullScreen
//        controller.delegate = self
//
//        currentVideoController = controller
//
//        delegate?.willPresentVideo(url: url, at: state.currentTime)
//
//        topVC.present(controller, animated: true) {
//            let seekTime = CMTime(seconds: state.currentTime, preferredTimescale: 600)
//            player.seek(to: seekTime) { success in
//                if success && state.isPlaying {
//                    player.play()
//                    print("✅ SNS: Video playback started")
//                } else {
//                    print("⚠️ SNS: Seek or playback failed")
//                }
//            }
//        }
//    }
//
//    // MARK: - Image State Restore
//
//    private func checkAndRestoreImage(retryCount: Int = 3) {
//        print("🖼️ SNS: Checking for pending image (attempt \(4 - retryCount))")
//
//        guard let defaults = UserDefaults(suiteName: SNSNotificationConstants.appGroupIdentifier),
//              let data = defaults.data(forKey: StorageKeys.imageState),
//              let imageState = try? JSONDecoder().decode(SNSImageState.self, from: data),
//              let url = URL(string: imageState.url),
//              let topVC = getTopViewController()
//        else {
//            if retryCount > 0 {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                    self.checkAndRestoreImage(retryCount: retryCount - 1)
//                }
//            } else {
//                print("📭 SNS: No saved image state found")
//            }
//            return
//        }
//
//        defaults.removeObject(forKey: StorageKeys.imageState)
//
//        let imageVC = SNSImageFullscreenViewController(imageURL: url)
//        topVC.present(imageVC, animated: true)
//    }
//
//    // MARK: - Save State Helpers
//
//    private func saveVideoState(_ state: SNSVideoState) {
//        guard let encoded = try? JSONEncoder().encode(state),
//              let defaults = UserDefaults(suiteName: SNSNotificationConstants.appGroupIdentifier) else {
//            print("❌ SNS: Failed to save video state")
//            return
//        }
//
//        defaults.set(encoded, forKey: StorageKeys.videoState)
//        defaults.synchronize()
//
//        print("✅ SNS: Video state saved")
//    }
//
//    private func saveImageState(_ state: SNSImageState) {
//        guard let encoded = try? JSONEncoder().encode(state),
//              let defaults = UserDefaults(suiteName: SNSNotificationConstants.appGroupIdentifier) else {
//            print("❌ SNS: Failed to save image state")
//            return
//        }
//
//        defaults.set(encoded, forKey: StorageKeys.imageState)
//        defaults.synchronize()
//
//        print("✅ SNS: Image state saved")
//    }
//
//    private func handleNotificationPayload(_ userInfo: [String: Any]) {
//        print("📨 SNS: handleNotificationPayload called")
//
//        if let videoURL = userInfo["video_url"] as? String {
//            let time = userInfo["video_current_time"] as? Double ?? 0
//            let isPlaying = userInfo["video_is_playing"] as? Bool ?? true
//
//            let videoState = SNSVideoState(url: videoURL, currentTime: time, isPlaying: isPlaying)
//            saveVideoState(videoState)
//        }
//
//        if let imageURL = userInfo["image_url"] as? String {
//            let imageState = SNSImageState(url: imageURL)
//            saveImageState(imageState)
//        }
//    }
//
//    // MARK: - Push Notification Registration
//
//    public func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
//        let options: UNAuthorizationOptions = [.alert, .badge, .sound, .criticalAlert]
//        UNUserNotificationCenter.current().requestAuthorization(options: options, completionHandler: completion)
//    }
//
//    public func registerForNotifications() {
//        DispatchQueue.main.async {
//            UIApplication.shared.registerForRemoteNotifications()
//        }
//    }
//
//    public func setDeviceToken(_ deviceToken: Data) {
//        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
//        self.deviceToken = token
//        print("✅ SNS: Registered device token: \(token)")
//        delegate?.didRegisterDeviceToken(token)
//    }
//
//    // MARK: - Location Updates
//
//    public func updateDeviceLocation(_ coordinate: CLLocationCoordinate2D) {
//        print("📍 SNS: updateDeviceLocation lat:\(coordinate.latitude), lon:\(coordinate.longitude)")
//        // Optional send to backend
//    }
//
//    // MARK: - Utility
//
//    private func getTopViewController() -> UIViewController? {
//        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//              let window = windowScene.windows.first(where: { $0.isKeyWindow }),
//              let rootVC = window.rootViewController else {
//            return nil
//        }
//
//        var top = rootVC
//        while let presented = top.presentedViewController {
//            top = presented
//        }
//        return top
//    }
//
//    private func convertUserInfo(_ userInfo: [AnyHashable: Any]) -> [String: Any] {
//        var result: [String: Any] = [:]
//        for (key, value) in userInfo {
//            if let keyString = key as? String {
//                result[keyString] = value
//            }
//        }
//        return result
//    }
//}
//
//// MARK: - Push Notification Delegate
//
//extension SNSNotificationManager: UNUserNotificationCenterDelegate {
//    public func userNotificationCenter(_ center: UNUserNotificationCenter,
//                                       willPresent notification: UNNotification,
//                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
//        delegate?.didReceiveNotification(notification)
//        completionHandler([.banner, .sound])
//    }
//
//    public func userNotificationCenter(_ center: UNUserNotificationCenter,
//                                       didReceive response: UNNotificationResponse,
//                                       withCompletionHandler completionHandler: @escaping () -> Void) {
//        print("🔔 SNS: Notification tapped")
//
//        let payload = convertUserInfo(response.notification.request.content.userInfo)
//        handleNotificationPayload(payload)
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
//            self.checkAndRestoreVideo(retryCount: 3) { videoRestored in
//                if !videoRestored {
//                    self.checkAndRestoreImage(retryCount: 3)
//                }
//            }
//        }
//
//        completionHandler()
//    }
//}
//
//// MARK: - SDK Error Enum
//
//public enum SNSError: Error {
//    case missingHashKey
//    case serverError(String)
//    case networkError(Error)
//    case registrationError(Error)
//
//    public var localizedDescription: String {
//        switch self {
//        case .missingHashKey: return "Missing hash key"
//        case .serverError(let msg): return msg
//        case .networkError(let err): return err.localizedDescription
//        case .registrationError(let err): return err.localizedDescription
//        }
//    }
//}


 //registing in the backend and also updating location when user enters the app
//import UIKit
//import UserNotifications
//import CoreLocation
//import AVKit
//
//// MARK: - Public Protocol
//
//public protocol SNSNotificationDelegate: AnyObject {
//    func didRegisterDeviceToken(_ token: String)
//    func didReceiveNotification(_ notification: UNNotification)
//    func registrationFailed(error: SNSError)
//    func willPresentVideo(url: URL, at time: Double)
//    func didCompleteVideoPresentation()
//}
//
//public extension SNSNotificationDelegate {
//    func willPresentVideo(url: URL, at time: Double) {}
//    func didCompleteVideoPresentation() {}
//}
//
//// MARK: - Main SDK Manager
//
//public final class SNSNotificationManager: NSObject, AVPlayerViewControllerDelegate {
//
//    public static let shared = SNSNotificationManager()
//    public weak var delegate: SNSNotificationDelegate?
//
//    private var hashKey: String?
//    private var deviceToken: String?
//    private var currentVideoController: AVPlayerViewController?
//    private var lastLocation: CLLocationCoordinate2D?
//    private var retryAttempts = 3
//    private let retryDelay: TimeInterval = 5.0
//
//    private struct StorageKeys {
//        static let videoState = "sns_pending_video_state"
//        static let imageState = "sns_pending_image_state"
//        static let savedDeviceToken = "sns_saved_device_token"
//        static let savedAndroidID = "sns_saved_android_id"
//        static let savedEndArn = "sns_saved_endArn"
//    }
//
//    private struct Config {
//        static let secretKey = "j4XnLx^=Xtj5_LE-7bw^sXA$3PxrTT72wU4ZS8uAsn#NaD6myryhA9L9JhT"
//        static let deviceType = "ios"
//    }
//
//    // MARK: - Quick Setup Entry
//
//    public static func quickSetup(
//        hashKey: String,
//        delegate: SNSNotificationDelegate? = nil,
//        enableLocationUpdates: Bool = true,
//        autoRegisterNotifications: Bool = true
//    ) {
//        let manager = SNSNotificationManager.shared
//        manager.delegate = delegate
//        manager.configure(hashKey: hashKey)
//
//        if autoRegisterNotifications {
//            manager.requestAuthorization { granted, error in
//                if granted {
//                    manager.registerForNotifications()
//                } else if let error = error {
//                    delegate?.registrationFailed(error: .registrationError(error))
//                }
//            }
//        }
//
//        UNUserNotificationCenter.current().delegate = manager
//
//        NotificationCenter.default.addObserver(
//            manager,
//            selector: #selector(manager.appDidBecomeActive),
//            name: UIApplication.didBecomeActiveNotification,
//            object: nil
//        )
//
//        if enableLocationUpdates {
//            SNSLocationManager.shared.startLocationUpdates()
//        }
//    }
//
//    private func configure(hashKey: String) {
//        self.hashKey = hashKey
//    }
//
//    // MARK: - App Lifecycle
//
//    public func handleAppLaunch(with launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
//        if let userInfo = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
//            handleNotificationPayload(convertUserInfo(userInfo))
//        }
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            self.checkAndRestoreVideo(retryCount: 3) { videoRestored in
//                if !videoRestored {
//                    self.checkAndRestoreImage(retryCount: 3)
//                }
//            }
//        }
//    }
//
//    @objc private func appDidBecomeActive() {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//            self.checkAndRestoreVideo(retryCount: 3) { videoRestored in
//                if !videoRestored {
//                    self.checkAndRestoreImage(retryCount: 3)
//                }
//            }
//        }
//    }
//
//    // MARK: - Push Notification
//
//    public func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
//        let options: UNAuthorizationOptions = [.alert, .badge, .sound, .criticalAlert]
//        UNUserNotificationCenter.current().requestAuthorization(options: options, completionHandler: completion)
//    }
//
//    public func registerForNotifications() {
//        DispatchQueue.main.async {
//            UIApplication.shared.registerForRemoteNotifications()
//        }
//    }
//
//    public func setDeviceToken(_ deviceToken: Data) {
//        let tokenString = deviceToken.map { String(format: "%02x", $0) }.joined()
//        self.deviceToken = tokenString
//        print("✅ SNS: Registered device token: \(tokenString)")
//        delegate?.didRegisterDeviceToken(tokenString)
//
//        let storedToken = UserDefaults.standard.string(forKey: StorageKeys.savedDeviceToken)
//        if storedToken == tokenString {
//            if let location = lastLocation {
//                sendLocationUpdate(location)
//            }
//        } else {
//            registerDevice(tokenString)
//            UserDefaults.standard.set(tokenString, forKey: StorageKeys.savedDeviceToken)
//        }
//    }
//
//    public func updateDeviceLocation(_ coordinate: CLLocationCoordinate2D) {
//        print("📍 SNS: App updated to location lat:\(coordinate.latitude), lon:\(coordinate.longitude)")
//
//        if let last = lastLocation {
//            let distance = CLLocation(latitude: last.latitude, longitude: last.longitude)
//                .distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
//            if distance < 100 {
//                print("📏 SNS: Ignored movement <100m")
//                return
//            }
//        }
//
//        lastLocation = coordinate
//        sendLocationUpdate(coordinate)
//    }
//
//    // MARK: - Notification + Media State
//
//    private func handleNotificationPayload(_ userInfo: [String: Any]) {
//        if let videoURL = userInfo["video_url"] as? String {
//            let time = userInfo["video_current_time"] as? Double ?? 0
//            let isPlaying = userInfo["video_is_playing"] as? Bool ?? true
//            let state = SNSVideoState(url: videoURL, currentTime: time, isPlaying: isPlaying)
//            saveVideoState(state)
//        }
//
//        if let imageURL = userInfo["image_url"] as? String {
//            let state = SNSImageState(url: imageURL)
//            saveImageState(state)
//        }
//    }
//
//    private func checkAndRestoreVideo(retryCount: Int = 3, completion: ((Bool) -> Void)? = nil) {
//        guard let defaults = UserDefaults(suiteName: SNSNotificationConstants.appGroupIdentifier),
//              let data = defaults.data(forKey: StorageKeys.videoState),
//              let state = try? JSONDecoder().decode(SNSVideoState.self, from: data)
//        else {
//            if retryCount > 0 {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                    self.checkAndRestoreVideo(retryCount: retryCount - 1, completion: completion)
//                }
//            } else {
//                completion?(false)
//            }
//            return
//        }
//
//        defaults.removeObject(forKey: StorageKeys.videoState)
//        presentVideo(from: state)
//        completion?(true)
//    }
//
//    private func checkAndRestoreImage(retryCount: Int = 3) {
//        guard let defaults = UserDefaults(suiteName: SNSNotificationConstants.appGroupIdentifier),
//              let data = defaults.data(forKey: StorageKeys.imageState),
//              let state = try? JSONDecoder().decode(SNSImageState.self, from: data),
//              let url = URL(string: state.url),
//              let topVC = getTopViewController()
//        else {
//            if retryCount > 0 {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                    self.checkAndRestoreImage(retryCount: retryCount - 1)
//                }
//            }
//            return
//        }
//
//        defaults.removeObject(forKey: StorageKeys.imageState)
//        topVC.present(SNSImageFullscreenViewController(imageURL: url), animated: true)
//    }
//
//    private func presentVideo(from state: SNSVideoState) {
//        guard let url = URL(string: state.url),
//              let topVC = getTopViewController() else {
//            return
//        }
//
//        if let existing = currentVideoController {
//            existing.dismiss(animated: false)
//        }
//
//        let player = AVPlayer(url: url)
//        let controller = AVPlayerViewController()
//        controller.player = player
//        controller.modalPresentationStyle = .fullScreen
//        controller.delegate = self
//
//        currentVideoController = controller
//        delegate?.willPresentVideo(url: url, at: state.currentTime)
//
//        topVC.present(controller, animated: true) {
//            let seekTime = CMTime(seconds: state.currentTime, preferredTimescale: 600)
//            player.seek(to: seekTime) { success in
//                if success && state.isPlaying {
//                    player.play()
//                }
//            }
//        }
//    }
//
//    private func saveVideoState(_ state: SNSVideoState) {
//        guard let data = try? JSONEncoder().encode(state),
//              let defaults = UserDefaults(suiteName: SNSNotificationConstants.appGroupIdentifier) else { return }
//        defaults.set(data, forKey: StorageKeys.videoState)
//        defaults.synchronize()
//    }
//
//    private func saveImageState(_ state: SNSImageState) {
//        guard let data = try? JSONEncoder().encode(state),
//              let defaults = UserDefaults(suiteName: SNSNotificationConstants.appGroupIdentifier) else { return }
//        defaults.set(data, forKey: StorageKeys.imageState)
//        defaults.synchronize()
//    }
//
//    private func convertUserInfo(_ userInfo: [AnyHashable: Any]) -> [String: Any] {
//        var result = [String: Any]()
//        for (key, value) in userInfo {
//            if let keyStr = key as? String {
//                result[keyStr] = value
//            }
//        }
//        return result
//    }
//
//    private func getTopViewController() -> UIViewController? {
//        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//              let window = windowScene.windows.first(where: { $0.isKeyWindow }),
//              let rootVC = window.rootViewController else { return nil }
//
//        var top = rootVC
//        while let presented = top.presentedViewController {
//            top = presented
//        }
//
//        return top
//    }
//
//    // MARK: - Device Registration & Location Sending
//
//    private func registerDevice(_ token: String) {
//        guard let hashKey = hashKey else {
//            delegate?.registrationFailed(error: .missingHashKey)
//            return
//        }
//
//        let request = DeviceRegistrationRequest(
//            secretKey: Config.secretKey,
//            hashKey: hashKey,
//            lat: String(lastLocation?.latitude ?? 0),
//            lng: String(lastLocation?.longitude ?? 0),
//            endArn: token,
//            fcmToken: token,
//            deviceToken: token,
//            deviceType: Config.deviceType,
//            androidID: ""
//        )
//
//        SNSBackendService().registerDevice(request: request) { [weak self] result in
//            switch result {
//            case .success(let responseData):
//                guard let data = responseData.data(using: .utf8),
//                      let response = try? JSONDecoder().decode(DeviceRegistrationResponse.self, from: data) else { return }
//
//                UserDefaults.standard.set(response.endArn, forKey: StorageKeys.savedEndArn)
//                UserDefaults.standard.set(response.androidID, forKey: StorageKeys.savedAndroidID)
//
//            case .failure(let error):
//                self?.retryAttempts -= 1
//                if self?.retryAttempts ?? 0 > 0 {
//                    DispatchQueue.global().asyncAfter(deadline: .now() + self!.retryDelay) {
//                        self?.registerDevice(token)
//                    }
//                } else {
//                    self?.delegate?.registrationFailed(error: error)
//                }
//            }
//        }
//    }
//
//    private func sendLocationUpdate(_ location: CLLocationCoordinate2D) {
//        guard let hashKey = hashKey, let deviceToken = deviceToken else { return }
//
//        let request = DeviceRegistrationRequest(
//            secretKey: Config.secretKey,
//            hashKey: hashKey,
//            lat: String(location.latitude),
//            lng: String(location.longitude),
//            endArn: UserDefaults.standard.string(forKey: StorageKeys.savedEndArn) ?? "",
//            fcmToken: UserDefaults.standard.string(forKey: StorageKeys.savedEndArn) ?? "",
//            deviceToken: UserDefaults.standard.string(forKey: StorageKeys.savedAndroidID) ?? "",
//            deviceType: Config.deviceType,
//            androidID: UserDefaults.standard.string(forKey: StorageKeys.savedAndroidID) ?? ""
//        )
//
//        SNSBackendService().sendLocation(request: request) { _ in }
//    }
//}
//
//// MARK: - Notification Delegate
//
//extension SNSNotificationManager: UNUserNotificationCenterDelegate {
//    public func userNotificationCenter(_ center: UNUserNotificationCenter,
//                                       willPresent notification: UNNotification,
//                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
//        delegate?.didReceiveNotification(notification)
//        completionHandler([.banner, .sound])
//    }
//
//    public func userNotificationCenter(_ center: UNUserNotificationCenter,
//                                       didReceive response: UNNotificationResponse,
//                                       withCompletionHandler completionHandler: @escaping () -> Void) {
//        let payload = convertUserInfo(response.notification.request.content.userInfo)
//        handleNotificationPayload(payload)
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
//            self.checkAndRestoreVideo(retryCount: 3) { videoRestored in
//                if !videoRestored {
//                    self.checkAndRestoreImage(retryCount: 3)
//                }
//            }
//        }
//
//        completionHandler()
//    }
//}
//
//// MARK: - Backend Networking Models
//
//private struct DeviceRegistrationRequest: Codable {
//    let secretKey: String
//    let hashKey: String
//    let lat: String
//    let lng: String
//    let endArn: String
//    let fcmToken: String
//    let deviceToken: String
//    let deviceType: String
//    let androidID: String
//}
//
//private struct DeviceRegistrationResponse: Codable {
//    let androidID: String
//    let endArn: String
//}
//
//private class SNSBackendService {
//    private let registrationURL = URL(string: "https://www.awakenalerts.com/awakenAPI/addDevice")!
//    private let locationUpdateURL = URL(string: "https://www.awakenalerts.com/awakenAPI/addLocation")!
//
//    func registerDevice(request: DeviceRegistrationRequest, completion: @escaping (Result<String, SNSError>) -> Void) {
//        var urlRequest = URLRequest(url: registrationURL)
//        urlRequest.httpMethod = "POST"
//        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        urlRequest.httpBody = try? JSONEncoder().encode(request)
//
//        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
//            if let error = error {
//                completion(.failure(.networkError(error)))
//                return
//            }
//
//            guard let data = data,
//                  let responseStr = String(data: data, encoding: .utf8),
//                  let httpStatus = (response as? HTTPURLResponse)?.statusCode,
//                  (200...299).contains(httpStatus) else {
//                completion(.failure(.serverError((response as? HTTPURLResponse)?.statusCode ?? 500)))
//                return
//            }
//
//            completion(.success(responseStr))
//        }.resume()
//    }
//
//    func sendLocation(request: DeviceRegistrationRequest, completion: @escaping (Result<Void, SNSError>) -> Void) {
//        var urlRequest = URLRequest(url: locationUpdateURL)
//        urlRequest.httpMethod = "POST"
//        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        urlRequest.httpBody = try? JSONEncoder().encode(request)
//
//        URLSession.shared.dataTask(with: urlRequest) { _, response, error in
//            if let error = error {
//                completion(.failure(.networkError(error)))
//                return
//            }
//
//            guard let httpStatus = (response as? HTTPURLResponse)?.statusCode,
//                  (200...299).contains(httpStatus) else {
//                completion(.failure(.serverError((response as? HTTPURLResponse)?.statusCode ?? 500)))
//                return
//            }
//
//            completion(.success(()))
//        }.resume()
//    }
//}
//
//// MARK: - SDK Error Enum
//
//public enum SNSError: Error {
//    case missingHashKey
//    case serverError(Int)
//    case networkError(Error)
//    case registrationError(Error)
//
//    public var localizedDescription: String {
//        switch self {
//        case .missingHashKey: return "Missing hash key"
//        case .serverError(let code): return "Server Error: \(code)"
//        case .networkError(let err): return err.localizedDescription
//        case .registrationError(let err): return err.localizedDescription
//        }
//    }
//}




//wprked till here using manus

//import UIKit
//import UserNotifications
//import CoreLocation
//import AVKit
//
//// MARK: - Public Protocol
//
//public protocol SNSNotificationDelegate: AnyObject {
//    func didRegisterDeviceToken(_ token: String)
//    func didReceiveNotification(_ notification: UNNotification)
//    func registrationFailed(error: SNSError)
//    func willPresentVideo(url: URL, at time: Double)
//    func didCompleteVideoPresentation()
//}
//
//public extension SNSNotificationDelegate {
//    func willPresentVideo(url: URL, at time: Double) {}
//    func didCompleteVideoPresentation() {}
//}
//
//// MARK: - Main SDK Manager
//
//public final class SNSNotificationManager: NSObject, AVPlayerViewControllerDelegate {
//
//    public static let shared = SNSNotificationManager()
//    public weak var delegate: SNSNotificationDelegate?
//
//    private var hashKey: String?
//    private var deviceToken: String?
//    private var currentVideoController: AVPlayerViewController?
//    private var lastLocation: CLLocationCoordinate2D?
//    private var retryAttempts = 3
//    private let retryDelay: TimeInterval = 5.0
//    private var isLaunchingFromNotification = false // New flag
//
//    private struct StorageKeys {
//        static let videoState = "sns_pending_video_state"
//        static let imageState = "sns_pending_image_state"
//        static let savedDeviceToken = "sns_saved_device_token"
//        static let savedAndroidID = "sns_saved_android_id"
//        static let savedEndArn = "sns_saved_endArn"
//    }
//
//    private struct Config {
//        static let secretKey = "j4XnLx^=Xtj5_LE-7bw^sXA$3PxrTT72wU4ZS8uAsn#NaD6myryhA9L9JhT"
//        static let deviceType = "ios"
//    }
//
//    // MARK: - Quick Setup Entry
//
//    public static func quickSetup(
//        hashKey: String,
//        delegate: SNSNotificationDelegate? = nil,
//        enableLocationUpdates: Bool = true,
//        autoRegisterNotifications: Bool = true
//    ) {
//        let manager = SNSNotificationManager.shared
//        manager.delegate = delegate
//        manager.configure(hashKey: hashKey)
//
//        if autoRegisterNotifications {
//            manager.requestAuthorization { granted, error in
//                if granted {
//                    manager.registerForNotifications()
//                } else if let error = error {
//                    delegate?.registrationFailed(error: .registrationError(error))
//                }
//            }
//        }
//
//        UNUserNotificationCenter.current().delegate = manager
//
//        NotificationCenter.default.addObserver(
//            manager,
//            selector: #selector(manager.appDidBecomeActive),
//            name: UIApplication.didBecomeActiveNotification,
//            object: nil
//        )
//
//        if enableLocationUpdates {
//            SNSLocationManager.shared.startLocationUpdates()
//        }
//    }
//
//    private func configure(hashKey: String) {
//        self.hashKey = hashKey
//    }
//
//    // MARK: - App Lifecycle
//
//    public func handleAppLaunch(with launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
//        if let userInfo = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
//            isLaunchingFromNotification = true
//            handleNotificationPayload(convertUserInfo(userInfo))
//        }
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            self.checkAndRestoreVideo(retryCount: 3) { videoRestored in
//                if !videoRestored {
//                    self.checkAndRestoreImage(retryCount: 3)
//                }
//                self.isLaunchingFromNotification = false // Reset the flag
//            }
//        }
//    }
//
//    @objc private func appDidBecomeActive() {
//        // Only attempt to restore video if launched from notification or if there's a pending video state
//        // and it's not already playing.
//        if !isLaunchingFromNotification && currentVideoController?.player?.rate == 0 {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//                self.checkAndRestoreVideo(retryCount: 3) { videoRestored in
//                    if !videoRestored {
//                        self.checkAndRestoreImage(retryCount: 3)
//                    }
//                }
//            }
//        }
//    }
//
//    // MARK: - Push Notification
//
//    public func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
//        let options: UNAuthorizationOptions = [.alert, .badge, .sound, .criticalAlert]
//        UNUserNotificationCenter.current().requestAuthorization(options: options, completionHandler: completion)
//    }
//
//    public func registerForNotifications() {
//        DispatchQueue.main.async {
//            UIApplication.shared.registerForRemoteNotifications()
//        }
//    }
//
//    public func setDeviceToken(_ deviceToken: Data) {
//        let tokenString = deviceToken.map { String(format: "%02x", $0) }.joined()
//        self.deviceToken = tokenString
//        print("✅ SNS: Registered device token: \(tokenString)")
//        delegate?.didRegisterDeviceToken(tokenString)
//
//        let storedToken = UserDefaults.standard.string(forKey: StorageKeys.savedDeviceToken)
//        if storedToken == tokenString {
//            if let location = lastLocation {
//                sendLocationUpdate(location)
//            }
//        } else {
//            registerDevice(tokenString)
//            UserDefaults.standard.set(tokenString, forKey: StorageKeys.savedDeviceToken)
//        }
//    }
//
//    public func updateDeviceLocation(_ coordinate: CLLocationCoordinate2D) {
//        print("📍 SNS: App updated to location lat:\(coordinate.latitude), lon:\(coordinate.longitude)")
//
//        if let last = lastLocation {
//            let distance = CLLocation(latitude: last.latitude, longitude: last.longitude)
//                .distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
//            if distance < 100 {
//                print("📏 SNS: Ignored movement <100m")
//                return
//            }
//        }
//
//        lastLocation = coordinate
//        sendLocationUpdate(coordinate)
//    }
//
//    // MARK: - Notification + Media State
//
//    private func handleNotificationPayload(_ userInfo: [String: Any]) {
//        if let videoURL = userInfo["video_url"] as? String {
//            let time = userInfo["video_current_time"] as? Double ?? 0
//            let isPlaying = userInfo["video_is_playing"] as? Bool ?? true
//            let state = SNSVideoState(url: videoURL, currentTime: time, isPlaying: isPlaying)
//            saveVideoState(state)
//        }
//
//        if let imageURL = userInfo["image_url"] as? String {
//            let state = SNSImageState(url: imageURL)
//            saveImageState(state)
//        }
//    }
//
//    private func checkAndRestoreVideo(retryCount: Int = 3, completion: ((Bool) -> Void)? = nil) {
//        guard let defaults = UserDefaults(suiteName: SNSNotificationConstants.appGroupIdentifier),
//              let data = defaults.data(forKey: StorageKeys.videoState),
//              let state = try? JSONDecoder().decode(SNSVideoState.self, from: data)
//        else {
//            if retryCount > 0 {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                    self.checkAndRestoreVideo(retryCount: retryCount - 1, completion: completion)
//                }
//            } else {
//                completion?(false)
//            }
//            return
//        }
//
//        defaults.removeObject(forKey: StorageKeys.videoState)
//        presentVideo(from: state)
//        completion?(true)
//    }
//
//    private func checkAndRestoreImage(retryCount: Int = 3) {
//        guard let defaults = UserDefaults(suiteName: SNSNotificationConstants.appGroupIdentifier),
//              let data = defaults.data(forKey: StorageKeys.imageState),
//              let state = try? JSONDecoder().decode(SNSImageState.self, from: data),
//              let url = URL(string: state.url),
//              let topVC = getTopViewController()
//        else {
//            if retryCount > 0 {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                    self.checkAndRestoreImage(retryCount: retryCount - 1)
//                }
//            }
//            return
//        }
//
//        defaults.removeObject(forKey: StorageKeys.imageState)
//        topVC.present(SNSImageFullscreenViewController(imageURL: url), animated: true)
//    }
//
//    private func presentVideo(from state: SNSVideoState) {
//        guard let url = URL(string: state.url),
//              let topVC = getTopViewController() else {
//            return
//        }
//
//        // If a video is already playing and it's the same video, just seek to the time
//        if let existing = currentVideoController, existing.player?.currentItem?.asset == AVAsset(url: url) {
//            let seekTime = CMTime(seconds: state.currentTime, preferredTimescale: 600)
//            existing.player?.seek(to: seekTime) { success in
//                if success && state.isPlaying {
//                    existing.player?.play()
//                }
//            }
//            return
//        }
//
//        // Dismiss any existing video controller if it's different or not playing
//        if let existing = currentVideoController {
//            existing.dismiss(animated: false) { [weak self] in
//                self?.currentVideoController = nil
//            }
//        }
//
//        let player = AVPlayer(url: url)
//        let controller = AVPlayerViewController()
//        controller.player = player
//        controller.modalPresentationStyle = .fullScreen
//        controller.delegate = self
//
//        currentVideoController = controller
//        delegate?.willPresentVideo(url: url, at: state.currentTime)
//
//        topVC.present(controller, animated: true) {
//            let seekTime = CMTime(seconds: state.currentTime, preferredTimescale: 600)
//            player.seek(to: seekTime) { success in
//                if success && state.isPlaying {
//                    player.play()
//                }
//            }
//        }
//    }
//
//    private func saveVideoState(_ state: SNSVideoState) {
//        guard let data = try? JSONEncoder().encode(state),
//              let defaults = UserDefaults(suiteName: SNSNotificationConstants.appGroupIdentifier) else { return }
//        defaults.set(data, forKey: StorageKeys.videoState)
//        defaults.synchronize()
//    }
//
//    private func saveImageState(_ state: SNSImageState) {
//        guard let data = try? JSONEncoder().encode(state),
//              let defaults = UserDefaults(suiteName: SNSNotificationConstants.appGroupIdentifier) else { return }
//        defaults.set(data, forKey: StorageKeys.imageState)
//        defaults.synchronize()
//    }
//
//    private func convertUserInfo(_ userInfo: [AnyHashable: Any]) -> [String: Any] {
//        var result = [String: Any]()
//        for (key, value) in userInfo {
//            if let keyStr = key as? String {
//                result[keyStr] = value
//            }
//        }
//        return result
//    }
//
//    private func getTopViewController() -> UIViewController? {
//        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//              let window = windowScene.windows.first(where: { $0.isKeyWindow }),
//              let rootVC = window.rootViewController else { return nil }
//
//        var top = rootVC
//        while let presented = top.presentedViewController {
//            top = presented
//        }
//
//        return top
//    }
//
//    // MARK: - Device Registration & Location Sending
//
//    private func registerDevice(_ token: String) {
//        guard let hashKey = hashKey else {
//            delegate?.registrationFailed(error: .missingHashKey)
//            return
//        }
//
//        let request = DeviceRegistrationRequest(
//            secretKey: Config.secretKey,
//            hashKey: hashKey,
//            lat: String(lastLocation?.latitude ?? 0),
//            lng: String(lastLocation?.longitude ?? 0),
//            endArn: token,
//            fcmToken: token,
//            deviceToken: token,
//            deviceType: Config.deviceType,
//            androidID: ""
//        )
//
//        SNSBackendService().registerDevice(request: request) { [weak self] result in
//            switch result {
//            case .success(let responseData):
//                guard let data = responseData.data(using: .utf8),
//                      let response = try? JSONDecoder().decode(DeviceRegistrationResponse.self, from: data) else { return }
//
//                UserDefaults.standard.set(response.endArn, forKey: StorageKeys.savedEndArn)
//                UserDefaults.standard.set(response.androidID, forKey: StorageKeys.savedAndroidID)
//
//            case .failure(let error):
//                self?.retryAttempts -= 1
//                if self?.retryAttempts ?? 0 > 0 {
//                    DispatchQueue.global().asyncAfter(deadline: .now() + self!.retryDelay) {
//                        self?.registerDevice(token)
//                    }
//                } else {
//                    self?.delegate?.registrationFailed(error: error)
//                }
//            }
//        }
//    }
//
//    private func sendLocationUpdate(_ location: CLLocationCoordinate2D) {
//        guard let hashKey = hashKey, let deviceToken = deviceToken else { return }
//
//        let request = DeviceRegistrationRequest(
//            secretKey: Config.secretKey,
//            hashKey: hashKey,
//            lat: String(location.latitude),
//            lng: String(location.longitude),
//            endArn: UserDefaults.standard.string(forKey: StorageKeys.savedEndArn) ?? "",
//            fcmToken: UserDefaults.standard.string(forKey: StorageKeys.savedEndArn) ?? "",
//            deviceToken: UserDefaults.standard.string(forKey: StorageKeys.savedAndroidID) ?? "",
//            deviceType: Config.deviceType,
//            androidID: UserDefaults.standard.string(forKey: StorageKeys.savedAndroidID) ?? ""
//        )
//
//        SNSBackendService().sendLocation(request: request) { _ in }
//    }
//}
//
//// MARK: - Notification Delegate
//
//extension SNSNotificationManager: UNUserNotificationCenterDelegate {
//    public func userNotificationCenter(_ center: UNUserNotificationCenter,
//                                       willPresent notification: UNNotification,
//                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
//        delegate?.didReceiveNotification(notification)
//        completionHandler([.banner, .sound])
//    }
//
//    public func userNotificationCenter(_ center: UNUserNotificationCenter,
//                                       didReceive response: UNNotificationResponse,
//                                       withCompletionHandler completionHandler: @escaping () -> Void) {
//        let payload = convertUserInfo(response.notification.request.content.userInfo)
//        handleNotificationPayload(payload)
//
//        // Set the flag when a notification is tapped
//        isLaunchingFromNotification = true
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
//            self.checkAndRestoreVideo(retryCount: 3) { videoRestored in
//                if !videoRestored {
//                    self.checkAndRestoreImage(retryCount: 3)
//                }
//                self.isLaunchingFromNotification = false // Reset the flag after restoration attempt
//            }
//        }
//
//        completionHandler()
//    }
//}
//
//// MARK: - Backend Networking Models
//
//private struct DeviceRegistrationRequest: Codable {
//    let secretKey: String
//    let hashKey: String
//    let lat: String
//    let lng: String
//    let endArn: String
//    let fcmToken: String
//    let deviceToken: String
//    let deviceType: String
//    let androidID: String
//}
//
//private struct DeviceRegistrationResponse: Codable {
//    let androidID: String
//    let endArn: String
//}
//
//private class SNSBackendService {
//    private let registrationURL = URL(string: "https://www.awakenalerts.com/awakenAPI/addDevice")!
//    private let locationUpdateURL = URL(string: "https://www.awakenalerts.com/awakenAPI/addLocation")!
//
//    func registerDevice(request: DeviceRegistrationRequest, completion: @escaping (Result<String, SNSError>) -> Void) {
//        var urlRequest = URLRequest(url: registrationURL)
//        urlRequest.httpMethod = "POST"
//        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        urlRequest.httpBody = try? JSONEncoder().encode(request)
//
//        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
//            if let error = error {
//                completion(.failure(.networkError(error)))
//                return
//            }
//
//            guard let data = data,
//                  let responseStr = String(data: data, encoding: .utf8),
//                  let httpStatus = (response as? HTTPURLResponse)?.statusCode,
//                  (200...299).contains(httpStatus) else {
//                completion(.failure(.serverError((response as? HTTPURLResponse)?.statusCode ?? 500)))
//                return
//            }
//
//            completion(.success(responseStr))
//        }.resume()
//    }
//
//    func sendLocation(request: DeviceRegistrationRequest, completion: @escaping (Result<Void, SNSError>) -> Void) {
//        var urlRequest = URLRequest(url: locationUpdateURL)
//        urlRequest.httpMethod = "POST"
//        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        urlRequest.httpBody = try? JSONEncoder().encode(request)
//
//        URLSession.shared.dataTask(with: urlRequest) { _, response, error in
//            if let error = error {
//                completion(.failure(.networkError(error)))
//                return
//            }
//
//            guard let httpStatus = (response as? HTTPURLResponse)?.statusCode,
//                  (200...299).contains(httpStatus) else {
//                completion(.failure(.serverError((response as? HTTPURLResponse)?.statusCode ?? 500)))
//                return
//            }
//
//            completion(.success(()))
//        }.resume()
//    }
//}
//
//// MARK: - SDK Error Enum
//
//public enum SNSError: Error {
//    case missingHashKey
//    case serverError(Int)
//    case networkError(Error)
//    case registrationError(Error)
//
//    public var localizedDescription: String {
//        switch self {
//        case .missingHashKey: return "Missing hash key"
//        case .serverError(let code): return "Server Error: \(code)"
//        case .networkError(let err): return err.localizedDescription
//        case .registrationError(let err): return err.localizedDescription
//        }
//    }
//}





//trying new manus from preet
//
//  SNSNotificationManager.swift
//  SNSNotificationSDK
//
//  Awaken Mobile on 15/4/2025.
//

import UIKit
import UserNotifications
import CoreLocation
import AVKit

// MARK: - Public Protocol

public protocol SNSNotificationDelegate: AnyObject {
    func didRegisterDeviceToken(_ token: String)
    func didReceiveNotification(_ notification: UNNotification)
    func registrationFailed(error: SNSError)
    func willPresentVideo(url: URL, at time: Double)
    func didCompleteVideoPresentation()
}

public extension SNSNotificationDelegate {
    func willPresentVideo(url: URL, at time: Double) {}
    func didCompleteVideoPresentation() {}
}

// MARK: - Main SDK Manager

public final class SNSNotificationManager: NSObject, AVPlayerViewControllerDelegate {
    
    public static let shared = SNSNotificationManager()
    public weak var delegate: SNSNotificationDelegate?
    
    private var hashKey: String?
    private var deviceToken: String?
    private var currentVideoController: AVPlayerViewController?
    private var lastLocation: CLLocationCoordinate2D?
    private var retryAttempts = 3
    private let retryDelay: TimeInterval = 5.0
    private var isLaunchingFromNotification = false
    
    private struct StorageKeys {
        static let videoState = "sns_pending_video_state"
        static let imageState = "sns_pending_image_state"
        static let savedDeviceToken = "sns_saved_device_token"
        static let savedAndroidID = "sns_saved_android_id"
        static let savedEndArn = "sns_saved_endArn"
    }

    private struct Config {
        static let secretKey = "j4XnLx^=Xtj5_LE-7bw^sXA$3PxrTT72wU4ZS8uAsn#NaD6myryhA9L9JhT"
        static let deviceType = "ios"
    }

    // MARK: Setup Entrypoint

    public static func quickSetup(
        hashKey: String,
        delegate: SNSNotificationDelegate? = nil,
        enableLocationUpdates: Bool = true,
        autoRegisterNotifications: Bool = true
    ) {
        let manager = SNSNotificationManager.shared
        manager.delegate = delegate
        manager.configure(hashKey: hashKey)

        if autoRegisterNotifications {
            manager.requestAuthorization { granted, error in
                if granted {
                    manager.registerForNotifications()
                } else if let error = error {
                    delegate?.registrationFailed(error: .registrationError(error))
                }
            }
        }

        UNUserNotificationCenter.current().delegate = manager

        NotificationCenter.default.addObserver(
            manager,
            selector: #selector(manager.appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        if enableLocationUpdates {
            SNSLocationManager.shared.startLocationUpdates()
        }
    }

    private func configure(hashKey: String) {
        self.hashKey = hashKey
    }

    // MARK: App Lifecycle Handling

    public func handleAppLaunch(with launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        print("🚀 SNS: App launched")

        if let userInfo = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            isLaunchingFromNotification = true
            handleNotificationPayload(convertUserInfo(userInfo))
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.checkAndRestoreVideo(retryCount: 3) { videoRestored in
                if !videoRestored {
                    self.checkAndRestoreImage(retryCount: 3)
                }
                self.isLaunchingFromNotification = false
            }
        }
    }

    @objc private func appDidBecomeActive() {
        print("🔄 SNS: App became active")
        
        if !isLaunchingFromNotification && currentVideoController?.player?.rate == 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.checkAndRestoreVideo(retryCount: 3) { videoRestored in
                    if !videoRestored {
                        self.checkAndRestoreImage(retryCount: 3)
                    }
                }
            }
        }
    }

    // MARK: - Push Notification Registration

    public func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound, .criticalAlert]
        UNUserNotificationCenter.current().requestAuthorization(options: options, completionHandler: completion)
    }

    public func registerForNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    public func setDeviceToken(_ deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02x", $0) }.joined()
        self.deviceToken = tokenString
        print("✅ SNS: Registered device token: \(tokenString)")
        delegate?.didRegisterDeviceToken(tokenString)

        let storedToken = UserDefaults.standard.string(forKey: StorageKeys.savedDeviceToken)
        if storedToken == tokenString {
            if let location = lastLocation {
                sendLocationUpdate(location)
            }
        } else {
            registerDevice(tokenString)
            UserDefaults.standard.set(tokenString, forKey: StorageKeys.savedDeviceToken)
        }
    }

    public func updateDeviceLocation(_ coordinate: CLLocationCoordinate2D) {
        print("📍 SNS: App updated to location lat:\(coordinate.latitude), lon:\(coordinate.longitude)")

        if let last = lastLocation {
            let distance = CLLocation(latitude: last.latitude, longitude: last.longitude)
                .distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
            if distance < 100 {
                print("📏 SNS: Ignored movement <100m")
                return
            }
        }

        lastLocation = coordinate
        sendLocationUpdate(coordinate)
    }

    // MARK: - Device Registration & Location Sending

    private func registerDevice(_ token: String) {
        guard let hashKey = hashKey else {
            delegate?.registrationFailed(error: .missingHashKey)
            return
        }

        let request = DeviceRegistrationRequest(
            secretKey: Config.secretKey,
            hashKey: hashKey,
            lat: String(lastLocation?.latitude ?? 0),
            lng: String(lastLocation?.longitude ?? 0),
            endArn: token,
            fcmToken: token,
            deviceToken: token,
            deviceType: Config.deviceType,
            androidID: ""
        )

        SNSBackendService().registerDevice(request: request) { [weak self] result in
            switch result {
            case .success(let responseData):
                guard let data = responseData.data(using: .utf8),
                      let response = try? JSONDecoder().decode(DeviceRegistrationResponse.self, from: data) else { return }

                UserDefaults.standard.set(response.endArn, forKey: StorageKeys.savedEndArn)
                UserDefaults.standard.set(response.androidID, forKey: StorageKeys.savedAndroidID)

            case .failure(let error):
                self?.retryAttempts -= 1
                if self?.retryAttempts ?? 0 > 0 {
                    DispatchQueue.global().asyncAfter(deadline: .now() + self!.retryDelay) {
                        self?.registerDevice(token)
                    }
                } else {
                    self?.delegate?.registrationFailed(error: error)
                }
            }
        }
    }

    private func sendLocationUpdate(_ location: CLLocationCoordinate2D) {
        guard let hashKey = hashKey, let deviceToken = deviceToken else { return }

        let request = DeviceRegistrationRequest(
            secretKey: Config.secretKey,
            hashKey: hashKey,
            lat: String(location.latitude),
            lng: String(location.longitude),
            endArn: UserDefaults.standard.string(forKey: StorageKeys.savedEndArn) ?? "",
            fcmToken: UserDefaults.standard.string(forKey: StorageKeys.savedEndArn) ?? "",
            deviceToken: UserDefaults.standard.string(forKey: StorageKeys.savedAndroidID) ?? "",
            deviceType: Config.deviceType,
            androidID: UserDefaults.standard.string(forKey: StorageKeys.savedAndroidID) ?? ""
        )

        SNSBackendService().sendLocation(request: request) { _ in }
    }

    // MARK: - Video State Restore

    private func checkAndRestoreVideo(retryCount: Int = 3, completion: ((Bool) -> Void)? = nil) {
        print("🎬 SNS: Checking for pending video (attempt \(4 - retryCount))")

        guard let defaults = UserDefaults(suiteName: SNSNotificationConstants.appGroupIdentifier) else {
            print("❌ SNS: App group UserDefaults not accessible")
            completion?(false)
            return
        }

        guard let data = defaults.data(forKey: StorageKeys.videoState),
              let videoState = try? JSONDecoder().decode(SNSVideoState.self, from: data) else {

            if retryCount > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.checkAndRestoreVideo(retryCount: retryCount - 1, completion: completion)
                }
            } else {
                print("📭 SNS: No saved video state found")
                completion?(false)
            }

            return
        }

        defaults.removeObject(forKey: StorageKeys.videoState)
        presentVideo(from: videoState)
        completion?(true)
    }

    private func presentVideo(from state: SNSVideoState) {
        guard let url = URL(string: state.url) else {
            print("❌ SNS: Invalid video URL")
            return
        }

        guard let topVC = getTopViewController() else {
            print("❌ SNS: Unable to find top view controller")
            return
        }

        // If a video is already playing and it's the same video, just seek to the time
        if let existing = currentVideoController, existing.player?.currentItem?.asset == AVAsset(url: url) {
            let seekTime = CMTime(seconds: state.currentTime, preferredTimescale: 600)
            existing.player?.seek(to: seekTime) { success in
                if success && state.isPlaying {
                    existing.player?.play()
                }
            }
            return
        }

        // Dismiss any existing video controller if it's different or not playing
        if let existing = currentVideoController {
            existing.dismiss(animated: false) { [weak self] in
                self?.currentVideoController = nil
            }
        }

        // Configure AVAudioSession for video audio prioritization
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
            print("✅ SNS: AVAudioSession set to playback and activated.")
        } catch {
            print("❌ SNS: Failed to set audio session category: \(error.localizedDescription)")
        }

        let player = AVPlayer(url: url)
        let controller = AVPlayerViewController()
        controller.player = player
        controller.modalPresentationStyle = .fullScreen
        controller.delegate = self

        currentVideoController = controller
        delegate?.willPresentVideo(url: url, at: state.currentTime)

        topVC.present(controller, animated: true) {
            let seekTime = CMTime(seconds: state.currentTime, preferredTimescale: 600)
            player.seek(to: seekTime) { success in
                if success && state.isPlaying {
                    player.play()
                    print("✅ SNS: Video playback started")
                } else {
                    print("⚠️ SNS: Seek or playback failed")
                }
            }
        }
    }

    // MARK: - Image State Restore

    private func checkAndRestoreImage(retryCount: Int = 3) {
        print("🖼️ SNS: Checking for pending image (attempt \(4 - retryCount))")

        guard let defaults = UserDefaults(suiteName: SNSNotificationConstants.appGroupIdentifier),
              let data = defaults.data(forKey: StorageKeys.imageState),
              let imageState = try? JSONDecoder().decode(SNSImageState.self, from: data),
              let url = URL(string: imageState.url),
              let topVC = getTopViewController()
        else {
            if retryCount > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.checkAndRestoreImage(retryCount: retryCount - 1)
                }
            } else {
                print("📭 SNS: No saved image state found")
            }
            return
        }

        defaults.removeObject(forKey: StorageKeys.imageState)

        let imageVC = SNSImageFullscreenViewController(imageURL: url)
        topVC.present(imageVC, animated: true)
    }

    // MARK: - Save State Helpers

    private func saveVideoState(_ state: SNSVideoState) {
        guard let encoded = try? JSONEncoder().encode(state),
              let defaults = UserDefaults(suiteName: SNSNotificationConstants.appGroupIdentifier) else {
            print("❌ SNS: Failed to save video state")
            return
        }

        defaults.set(encoded, forKey: StorageKeys.videoState)
        defaults.synchronize()

        print("✅ SNS: Video state saved")
    }

    private func saveImageState(_ state: SNSImageState) {
        guard let encoded = try? JSONEncoder().encode(state),
              let defaults = UserDefaults(suiteName: SNSNotificationConstants.appGroupIdentifier) else {
            print("❌ SNS: Failed to save image state")
            return
        }

        defaults.set(encoded, forKey: StorageKeys.imageState)
        defaults.synchronize()

        print("✅ SNS: Image state saved")
    }

    private func handleNotificationPayload(_ userInfo: [String: Any]) {
        print("📨 SNS: handleNotificationPayload called")

        if let videoURL = userInfo["video_url"] as? String {
            let time = userInfo["video_current_time"] as? Double ?? 0
            let isPlaying = userInfo["video_is_playing"] as? Bool ?? true

            let videoState = SNSVideoState(url: videoURL, currentTime: time, isPlaying: isPlaying)
            saveVideoState(videoState)
        }

        if let imageURL = userInfo["image_url"] as? String {
            let imageState = SNSImageState(url: imageURL)
            saveImageState(imageState)
        }
    }

    // MARK: - AVPlayerViewControllerDelegate

    public func playerViewControllerWillEndPlayback(_ playerViewController: AVPlayerViewController) {
        print("👋 SNS: Video dismissed")
        currentVideoController = nil
        delegate?.didCompleteVideoPresentation()

        // Deactivate AVAudioSession when video playback ends
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            print("✅ SNS: AVAudioSession deactivated.")
        } catch {
            print("❌ SNS: Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }

    // MARK: - Utility

    private func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }),
              let rootVC = window.rootViewController else {
            return nil
        }

        var top = rootVC
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }

    private func convertUserInfo(_ userInfo: [AnyHashable: Any]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in userInfo {
            if let keyString = key as? String {
                result[keyString] = value
            }
        }
        return result
    }
}

// MARK: - Push Notification Delegate

extension SNSNotificationManager: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       willPresent notification: UNNotification,
                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        delegate?.didReceiveNotification(notification)
        completionHandler([.banner, .sound])
    }

    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       didReceive response: UNNotificationResponse,
                                       withCompletionHandler completionHandler: @escaping () -> Void) {
        print("🔔 SNS: Notification tapped")

        let payload = convertUserInfo(response.notification.request.content.userInfo)
        handleNotificationPayload(payload)

        // Set the flag when a notification is tapped
        isLaunchingFromNotification = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.checkAndRestoreVideo(retryCount: 3) { videoRestored in
                if !videoRestored {
                    self.checkAndRestoreImage(retryCount: 3)
                }
                self.isLaunchingFromNotification = false
            }
        }

        completionHandler()
    }
}

// MARK: - Backend Networking Models

private struct DeviceRegistrationRequest: Codable {
    let secretKey: String
    let hashKey: String
    let lat: String
    let lng: String
    let endArn: String
    let fcmToken: String
    let deviceToken: String
    let deviceType: String
    let androidID: String
}

private struct DeviceRegistrationResponse: Codable {
    let androidID: String
    let endArn: String
}

private class SNSBackendService {
    private let registrationURL = URL(string: "https://www.awakenalerts.com/awakenAPI/addDevice")!
    private let locationUpdateURL = URL(string: "https://www.awakenalerts.com/awakenAPI/addLocation")!

    func registerDevice(request: DeviceRegistrationRequest, completion: @escaping (Result<String, SNSError>) -> Void) {
        var urlRequest = URLRequest(url: registrationURL)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try? JSONEncoder().encode(request)

        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }

            guard let data = data,
                  let responseStr = String(data: data, encoding: .utf8),
                  let httpStatus = (response as? HTTPURLResponse)?.statusCode,
                  (200...299).contains(httpStatus) else {
                completion(.failure(.serverError((response as? HTTPURLResponse)?.statusCode ?? 500)))
                return
            }

            completion(.success(responseStr))
        }.resume()
    }

    func sendLocation(request: DeviceRegistrationRequest, completion: @escaping (Result<Void, SNSError>) -> Void) {
        var urlRequest = URLRequest(url: locationUpdateURL)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try? JSONEncoder().encode(request)

        URLSession.shared.dataTask(with: urlRequest) { _, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }

            guard let httpStatus = (response as? HTTPURLResponse)?.statusCode,
                  (200...299).contains(httpStatus) else {
                completion(.failure(.serverError((response as? HTTPURLResponse)?.statusCode ?? 500)))
                return
            }

            completion(.success(()))
        }.resume()
    }
}

// MARK: - SDK Error Enum

public enum SNSError: Error {
    case missingHashKey
    case serverError(Int)
    case networkError(Error)
    case registrationError(Error)

    public var localizedDescription: String {
        switch self {
        case .missingHashKey: return "Missing hash key"
        case .serverError(let code): return "Server Error: \(code)"
        case .networkError(let err): return err.localizedDescription
        case .registrationError(let err): return err.localizedDescription
        }
    }
}
