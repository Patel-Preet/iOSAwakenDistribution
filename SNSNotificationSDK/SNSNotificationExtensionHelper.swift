//
//  SNSNotificationExtensionHelper.swift
//  SNSNotificationSDK
//
//  Created by Awaken Mobile on 9/7/2025.
//

//working all good with sns voideo playing on app launch

//import Foundation
//import UserNotifications
//import UIKit
//import AVKit
//
//public final class SNSNotificationExtensionHelper {
//
//    private let containerView: UIView
//    private var playerController: AVPlayerViewController?
//    private var imageView: UIImageView?
//    private var currentVideoURL: URL?
//    private var timeObserver: Any?
//    private var videoStateTimer: Timer?
//    
//    public struct SNSImageState: Codable {
//        public let url: String
//        public let timestamp: Date
//
//        public init(url: String) {
//            self.url = url
//            self.timestamp = Date()
//        }
//    }
//    
//    private struct StorageKeys {
//        static let pendingVideoState = "sns_pending_video_state"
//    }
//
//    public init(containerView: UIView) {
//        self.containerView = containerView
//        print("🔧 SNS Extension Helper: Initialized")
//    }
//
//    // MARK: - Public Methods
//
//    public func render(notification: UNNotification) {
//        let content = notification.request.content
//        print("🔔 SNS Extension: Processing notification")
//        
//        // Try to get URL from subtitle first, then userInfo
//        var mediaURL: URL?
//        
//        if !content.subtitle.isEmpty {
//            mediaURL = URL(string: content.subtitle)
//        } else if let urlString = content.userInfo["video_url"] as? String {
//            mediaURL = URL(string: urlString)
//        } else if let urlString = content.userInfo["media_url"] as? String {
//            mediaURL = URL(string: urlString)
//        }
//        
//        guard let url = mediaURL else {
//            print("❌ SNS Extension: No valid media URL found")
//            return
//        }
//        
//        let fileExtension = url.pathExtension.lowercased()
//        cleanup()
//
//        if ["mp4", "mov", "m4v", "m3u8"].contains(fileExtension) {
//            currentVideoURL = url
//            playVideo(from: url)
//        } else if ["jpg", "jpeg", "png", "gif"].contains(fileExtension) {
//            loadImage(from: url)
//        } else {
//            print("⚠️ SNS Extension: Unsupported media type: \(fileExtension)")
//        }
//    }
//
//    public func saveCurrentVideoState() {
//        print("💾 SNS Extension: Manually saving video state...")
//        saveVideoStateToSharedStorage()
//    }
//
//    public func onNotificationResponse(_ response: UNNotificationResponse) {
//        print("📲 SNS Extension: Notification response received")
//        
//        // Save current video state if playing
//        saveVideoStateToSharedStorage()
//        
//        // Also save fallback state from notification payload
//        saveFallbackVideoState(from: response.notification.request.content.userInfo)
//    }
//
//    // MARK: - Video Handling
//
//    private func playVideo(from url: URL) {
//        print("🎬 SNS Extension: Setting up video player for: \(url)")
//        
//        let player = AVPlayer(url: url)
//        let controller = AVPlayerViewController()
//        controller.player = player
//        controller.showsPlaybackControls = true
//        controller.entersFullScreenWhenPlaybackBegins = false
//        controller.exitsFullScreenWhenPlaybackEnds = false
//        controller.view.frame = containerView.bounds
//        controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//
//        // Add to container
//        containerView.addSubview(controller.view)
//        if let parentVC = containerView.parentViewController {
//            parentVC.addChild(controller)
//            controller.didMove(toParent: parentVC)
//        }
//
//        // Setup time observer for continuous state tracking
//        timeObserver = player.addPeriodicTimeObserver(
//            forInterval: CMTime(seconds: 1.0, preferredTimescale: 600),
//            queue: .main
//        ) { [weak self] _ in
//            self?.periodicVideoStateUpdate()
//        }
//
//        // Start playback
//        player.play()
//        self.playerController = controller
//
//        // Hide fullscreen button after a delay
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            self.hideFullscreenButton(in: controller.view)
//        }
//
//        // Start periodic state saving
//        startPeriodicStateSaving()
//        
//        print("✅ SNS Extension: Video player setup complete")
//    }
//
//    private func loadImage(from url: URL) {
//        print("🖼️ SNS Extension: Loading image from: \(url)")
//        
//        let imageView = UIImageView(frame: containerView.bounds)
//        imageView.contentMode = .scaleAspectFill
//        imageView.clipsToBounds = true
//        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        containerView.addSubview(imageView)
//        self.imageView = imageView
//
//        URLSession.shared.dataTask(with: url) { data, _, error in
//            guard let data = data, error == nil,
//                  let image = UIImage(data: data) else {
//                print("❌ SNS Extension: Failed to load image: \(error?.localizedDescription ?? "Unknown error")")
//                return
//            }
//            DispatchQueue.main.async {
//                imageView.image = image
//                print("✅ SNS Extension: Image loaded successfully")
//            }
//        }.resume()
//    }
//
//    // MARK: - State Management
//
//    private func startPeriodicStateSaving() {
//        videoStateTimer?.invalidate()
//        videoStateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
//            self?.periodicVideoStateUpdate()
//        }
//    }
//
//    private func periodicVideoStateUpdate() {
//        // Save state every few seconds while playing
//        saveVideoStateToSharedStorage(silent: true)
//    }
//
//    private func saveVideoStateToSharedStorage(silent: Bool = false) {
//        guard let player = playerController?.player,
//              let url = currentVideoURL else {
//            if !silent { print("⚠️ SNS Extension: No active video to save") }
//            return
//        }
//
//        let currentTime = player.currentTime()
//        let isPlaying = player.rate > 0
//        
//        let videoState = SNSVideoState(
//            url: url.absoluteString,
//            currentTime: max(0, currentTime.seconds),
//            isPlaying: isPlaying
//        )
//
//        guard let data = try? JSONEncoder().encode(videoState) else {
//            if !silent { print("❌ SNS Extension: Failed to encode video state") }
//            return
//        }
//
//        guard let defaults = UserDefaults(suiteName: SNSNotificationConstants.appGroupIdentifier) else {
//            if !silent { print("❌ SNS Extension: Could not access App Group UserDefaults") }
//            return
//        }
//
//        defaults.set(data, forKey: StorageKeys.pendingVideoState)
//        defaults.synchronize()
//        
//        if !silent {
//            print("✅ SNS Extension: Video state saved - URL: \(url.absoluteString), Time: \(currentTime.seconds)s, Playing: \(isPlaying)")
//        }
//    }
//
//    private func saveFallbackVideoState(from userInfo: [AnyHashable: Any]) {
//        print("💾 SNS Extension: Saving fallback video state from payload")
//        
//        guard let videoURL = userInfo["video_url"] as? String else {
//            print("❌ SNS Extension: No video_url in payload")
//            return
//        }
//        
//        let currentTime = userInfo["video_current_time"] as? Double ?? 0
//        let isPlaying = userInfo["video_is_playing"] as? Bool ?? true
//        
//        let fallbackState = SNSVideoState(
//            url: videoURL,
//            currentTime: currentTime,
//            isPlaying: isPlaying
//        )
//
//        guard let data = try? JSONEncoder().encode(fallbackState),
//              let defaults = UserDefaults(suiteName: SNSNotificationConstants.appGroupIdentifier) else {
//            print("❌ SNS Extension: Failed to save fallback state")
//            return
//        }
//
//        // Only save fallback if no current state exists
//        if defaults.data(forKey: StorageKeys.pendingVideoState) == nil {
//            defaults.set(data, forKey: StorageKeys.pendingVideoState)
//            defaults.synchronize()
//            print("✅ SNS Extension: Fallback video state saved")
//        } else {
//            print("ℹ️ SNS Extension: Existing video state found, skipping fallback")
//        }
//    }
//
//    // MARK: - UI Utilities
//
//    private func hideFullscreenButton(in view: UIView) {
//        for subview in view.subviews {
//            if let button = subview as? UIButton {
//                // Try to identify fullscreen button by various characteristics
//                let hasSmallImageData = button.currentImage?.pngData()?.count ?? Int.max < 5000
//                let hasFullscreenAccessibility = button.accessibilityLabel?.lowercased().contains("full") == true
//                
//                if hasSmallImageData || hasFullscreenAccessibility {
//                    button.isHidden = true
//                    print("🔧 SNS Extension: Hidden potential fullscreen button")
//                }
//            }
//            hideFullscreenButton(in: subview)
//        }
//    }
//
//    // MARK: - Cleanup
//
//    private func cleanup() {
//        print("🧹 SNS Extension: Cleaning up previous media")
//        
//        // Stop timers
//        videoStateTimer?.invalidate()
//        videoStateTimer = nil
//        
//        // Remove time observer
//        if let timeObserver = timeObserver,
//           let player = playerController?.player {
//            player.removeTimeObserver(timeObserver)
//            self.timeObserver = nil
//        }
//        
//        // Remove UI elements
//        imageView?.removeFromSuperview()
//        if let playerController = playerController {
//            playerController.view.removeFromSuperview()
//            playerController.removeFromParent()
//        }
//        
//        // Clear references
//        imageView = nil
//        playerController = nil
//        currentVideoURL = nil
//    }
//    
//    deinit {
//        cleanup()
//        print("🔧 SNS Extension Helper: Deinitialized")
//    }
//}
//
//// MARK: - UIView Extension
//
//extension UIView {
//    var parentViewController: UIViewController? {
//        var parentResponder: UIResponder? = self
//        while let next = parentResponder?.next {
//            if let viewController = next as? UIViewController {
//                return viewController
//            }
//            parentResponder = next
//        }
//        return nil
//    }
//}





//image and video both working and location update in the background when app is launched

import Foundation
import UIKit
import AVKit
import UserNotifications

public struct SNSImageState: Codable {
    public let url: String
    public let timestamp: Date

    public init(url: String, timestamp: Date = Date()) {
        self.url = url
        self.timestamp = timestamp
    }
}

extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while let next = parentResponder?.next {
            if let vc = next as? UIViewController {
                return vc
            }
            parentResponder = next
        }
        return nil
    }
}

public final class SNSNotificationExtensionHelper {

    private let containerView: UIView
    private var playerController: AVPlayerViewController?
    private var imageView: UIImageView?
    private var currentVideoURL: URL?
    private var timeObserver: Any?
    private var videoStateTimer: Timer?

    private struct StorageKeys {
        static let pendingVideoState = "sns_pending_video_state"
        static let pendingImageState = "sns_pending_image_state"
    }

    public init(containerView: UIView) {
        self.containerView = containerView
        print("🔧 SNS Extension Helper: Initialized")
    }

    public func render(notification: UNNotification) {
        let content = notification.request.content
        print("🔔 SNS Extension: Processing notification")


            var mediaURL: URL?
        
            if !content.subtitle.isEmpty {
                mediaURL = URL(string: content.subtitle)
            } else if let urlString = content.userInfo["video_url"] as? String {
                mediaURL = URL(string: urlString)
            } else if let urlString = content.userInfo["image_url"] as? String {
                mediaURL = URL(string: urlString)
            }
        
        guard let url = mediaURL else {
            print("❌ SNS Extension: No valid media URL found")
            return
        }

        let fileExtension = url.pathExtension.lowercased()
        cleanup()

        if ["mp4", "mov", "m4v", "m3u8"].contains(fileExtension) {
            currentVideoURL = url
            playVideo(from: url)
        } else if ["jpg", "jpeg", "png", "gif", "heic", "webp"].contains(fileExtension) {
            loadImage(from: url)
        } else {
            print("⚠️ SNS Extension: Unsupported media type: \(fileExtension)")
        }
    }

    public func saveCurrentVideoState() {
        print("💾 SNS Extension: Manually saving video state...")
        saveVideoStateToSharedStorage()
    }

    public func onNotificationResponse(_ response: UNNotificationResponse) {
        print("📲 SNS Extension: Notification tapped")

        saveVideoStateToSharedStorage()
        saveFallbackVideoOrImageState(from: response.notification.request.content.userInfo)
    }

    private func playVideo(from url: URL) {
        print("🎬 SNS Extension: Setting up video player for: \(url)")

        let player = AVPlayer(url: url)
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        controller.entersFullScreenWhenPlaybackBegins = false
        controller.exitsFullScreenWhenPlaybackEnds = false
        controller.view.frame = containerView.bounds
        controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        containerView.addSubview(controller.view)

        if let parentVC = containerView.parentViewController {
            parentVC.addChild(controller)
            controller.didMove(toParent: parentVC)
        }

        self.timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 600), queue: .main) { [weak self] _ in
            self?.periodicVideoStateUpdate()
        }

        self.videoStateTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true, block: { [weak self] _ in
            self?.periodicVideoStateUpdate()
        })

        player.play()
        self.playerController = controller

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.hideFullscreenButton(in: controller.view)
        }

        print("✅ SNS Extension: Video player setup complete")
    }

    private func saveVideoStateToSharedStorage(silent: Bool = false) {
        guard let player = playerController?.player,
              let url = currentVideoURL else {
            if !silent { print("⚠️ SNS Extension: No video to save") }
            return
        }

        let currentTime = player.currentTime()
        let isPlaying = player.rate > 0

        let videoState = SNSVideoState(
            url: url.absoluteString,
            currentTime: max(0, currentTime.seconds),
            isPlaying: isPlaying
        )

        guard let data = try? JSONEncoder().encode(videoState),
              let defaults = UserDefaults(suiteName: SNSNotificationConstants.appGroupIdentifier) else {
            if !silent { print("❌ SNS Extension: Couldn't encode or access shared defaults") }
            return
        }

        defaults.set(data, forKey: StorageKeys.pendingVideoState)
        defaults.synchronize()

        if !silent {
            print("💾 SNS Extension: Video state saved - URL: \(url.absoluteString), Time: \(currentTime.seconds)s, Playing: \(isPlaying)")
        }
    }

    private func periodicVideoStateUpdate() {
        saveVideoStateToSharedStorage(silent: true)
    }

    private func loadImage(from url: URL) {
        print("🖼️ SNS Extension: Loading image from: \(url)")

        let imageView = UIImageView(frame: containerView.bounds)
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.addSubview(imageView)
        self.imageView = imageView

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let data = data, error == nil, let image = UIImage(data: data) else {
                print("❌ SNS Extension: Failed to load image: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            DispatchQueue.main.async {
                self?.imageView?.image = image
                print("✅ SNS Extension: Image loaded successfully")

                // Save SNSImageState in shared UserDefaults
                let state = SNSImageState(url: url.absoluteString)
                if let encoded = try? JSONEncoder().encode(state),
                   let defaults = UserDefaults(suiteName: SNSNotificationConstants.appGroupIdentifier) {
                    defaults.set(encoded, forKey: StorageKeys.pendingImageState)
                    defaults.synchronize()
                    print("💾 SNS Extension: Image state saved to shared container")
                } else {
                    print("❌ SNS Extension: Failed to save image state")
                }
            }
        }.resume()
    }

    private func saveFallbackVideoOrImageState(from userInfo: [AnyHashable: Any]) {
        print("💾 SNS Extension: Saving fallback state from payload")

        guard let defaults = UserDefaults(suiteName: SNSNotificationConstants.appGroupIdentifier) else {
            print("❌ SNS Extension: No shared defaults")
            return
        }

        if let videoURL = userInfo["video_url"] as? String {
            let currentTime = userInfo["video_current_time"] as? Double ?? 0
            let isPlaying = userInfo["video_is_playing"] as? Bool ?? true

            let videoState = SNSVideoState(url: videoURL, currentTime: currentTime, isPlaying: isPlaying)
            if let data = try? JSONEncoder().encode(videoState) {
                defaults.set(data, forKey: StorageKeys.pendingVideoState)
                defaults.synchronize()
                print("✅ SNS Extension: Fallback video state saved")
            }
        }

        if let imageURL = userInfo["image_url"] as? String {
            let imageState = SNSImageState(url: imageURL)
            if let data = try? JSONEncoder().encode(imageState) {
                defaults.set(data, forKey: StorageKeys.pendingImageState)
                defaults.synchronize()
                print("✅ SNS Extension: Fallback image state saved")
            }
        }
    }

    private func hideFullscreenButton(in view: UIView) {
        for subview in view.subviews {
            if let button = subview as? UIButton {
                let hasSmallImageData = button.currentImage?.pngData()?.count ?? Int.max < 5000
                let hasFullscreenAccessibility = button.accessibilityLabel?.lowercased().contains("full") == true

                if hasSmallImageData || hasFullscreenAccessibility {
                    button.isHidden = true
                    print("🔧 SNS Extension: Hidden potential fullscreen button")
                }
            }
            hideFullscreenButton(in: subview)
        }
    }

    private func cleanup() {
        print("🧹 SNS Extension: Cleaning up previous media")

        videoStateTimer?.invalidate()
        videoStateTimer = nil

        if let timeObserver = timeObserver,
           let player = playerController?.player {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }

        imageView?.removeFromSuperview()

        if let playerController = playerController {
            playerController.view.removeFromSuperview()
            playerController.removeFromParent()
        }

        imageView = nil
        playerController = nil
        currentVideoURL = nil
    }

    deinit {
        cleanup()
        print("🔧 SNS Extension Helper: Deinitialized")
    }
    
    
}





//import Foundation
//import UIKit
//import AVKit
//import UserNotifications
//
//public struct SNSImageState: Codable {
//    public let url: String
//    public let timestamp: Date
//
//    public init(url: String, timestamp: Date = Date()) {
//        self.url = url
//        self.timestamp = timestamp
//    }
//}
//
//extension UIView {
//    var parentViewController: UIViewController? {
//        var parentResponder: UIResponder? = self
//        while let next = parentResponder?.next {
//            if let vc = next as? UIViewController {
//                return vc
//            }
//            parentResponder = next
//        }
//        return nil
//    }
//}
//
//public final class SNSNotificationExtensionHelper {
//
//    private let containerView: UIView
//    private var playerController: AVPlayerViewController?
//    private var imageView: UIImageView?
//    private var currentVideoURL: URL?
//    private var timeObserver: Any?
//    private var videoStateTimer: Timer?
//    private var hasPlayedVideo = false // ✅ Prevent duplicate playback
//
//    private struct StorageKeys {
//        static let pendingVideoState = "sns_pending_video_state"
//        static let pendingImageState = "sns_pending_image_state"
//    }
//
//    public init(containerView: UIView) {
//        self.containerView = containerView
//        print("🔧 SNS Extension Helper: Initialized")
//    }
//
//    public func render(notification: UNNotification) {
//        let content = notification.request.content
//        print("🔔 SNS Extension: Processing notification")
//
//        var mediaURL: URL?
//
//        if !content.subtitle.isEmpty {
//            mediaURL = URL(string: content.subtitle)
//        } else if let urlString = content.userInfo["video_url"] as? String {
//            mediaURL = URL(string: urlString)
//        } else if let urlString = content.userInfo["image_url"] as? String {
//            mediaURL = URL(string: urlString)
//        }
//
//        guard let url = mediaURL else {
//            print("❌ SNS Extension: No valid media URL found")
//            return
//        }
//
//        let fileExtension = url.pathExtension.lowercased()
//        cleanup()
//
//        if ["mp4", "mov", "m4v", "m3u8"].contains(fileExtension) {
//            currentVideoURL = url
//            playVideo(from: url)
//        } else if ["jpg", "jpeg", "png", "gif", "heic", "webp"].contains(fileExtension) {
//            loadImage(from: url)
//        } else {
//            print("⚠️ SNS Extension: Unsupported media type: \(fileExtension)")
//        }
//    }
//
//    public func saveCurrentVideoState() {
//        print("💾 SNS Extension: Manually saving video state...")
//        saveVideoStateToSharedStorage()
//    }
//
//    public func onNotificationResponse(_ response: UNNotificationResponse) {
//        print("📲 SNS Extension: Notification tapped")
//
//        // ✅ Stop and clean up video before transitioning to app
//        stopVideo()
//
//        saveVideoStateToSharedStorage()
//        saveFallbackVideoOrImageState(from: response.notification.request.content.userInfo)
//    }
//
//    private func playVideo(from url: URL) {
//        guard !hasPlayedVideo else {
//            print("⛔️ SNS Extension: Duplicate playback prevented")
//            return
//        }
//
//        hasPlayedVideo = true
//        print("🎬 SNS Extension: Setting up video player for: \(url)")
//
//        let player = AVPlayer(url: url)
//        let controller = AVPlayerViewController()
//        controller.player = player
//        controller.showsPlaybackControls = true
//        controller.entersFullScreenWhenPlaybackBegins = false
//        controller.exitsFullScreenWhenPlaybackEnds = false
//        controller.view.frame = containerView.bounds
//        controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//
//        containerView.addSubview(controller.view)
//
//        if let parentVC = containerView.parentViewController {
//            parentVC.addChild(controller)
//            controller.didMove(toParent: parentVC)
//        }
//
//        self.timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 600), queue: .main) { [weak self] _ in
//            self?.periodicVideoStateUpdate()
//        }
//
//        self.videoStateTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true, block: { [weak self] _ in
//            self?.periodicVideoStateUpdate()
//        })
//
//        player.play()
//        self.playerController = controller
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            self.hideFullscreenButton(in: controller.view)
//        }
//
//        print("✅ SNS Extension: Video player setup complete")
//    }
//
//    private func stopVideo() {
//        print("⏸️ SNS Extension: Stopping video playback before app launch")
//
//        playerController?.player?.pause()
//        playerController?.player?.replaceCurrentItem(with: nil)
//        cleanup()
//    }
//
//    private func saveVideoStateToSharedStorage(silent: Bool = false) {
//        guard let player = playerController?.player,
//              let url = currentVideoURL else {
//            if !silent { print("⚠️ SNS Extension: No video to save") }
//            return
//        }
//
//        let currentTime = player.currentTime()
//        let isPlaying = player.rate > 0
//
//        let videoState = SNSVideoState(
//            url: url.absoluteString,
//            currentTime: max(0, currentTime.seconds),
//            isPlaying: isPlaying
//        )
//
//        guard let data = try? JSONEncoder().encode(videoState),
//              let defaults = UserDefaults(suiteName: SNSNotificationConstants.appGroupIdentifier) else {
//            if !silent { print("❌ SNS Extension: Couldn't encode or access shared defaults") }
//            return
//        }
//
//        defaults.set(data, forKey: StorageKeys.pendingVideoState)
//        defaults.synchronize()
//
//        if !silent {
//            print("💾 SNS Extension: Video state saved - URL: \(url.absoluteString), Time: \(currentTime.seconds)s, Playing: \(isPlaying)")
//        }
//    }
//
//    private func periodicVideoStateUpdate() {
//        saveVideoStateToSharedStorage(silent: true)
//    }
//
//    private func loadImage(from url: URL) {
//        print("🖼️ SNS Extension: Loading image from: \(url)")
//
//        let imageView = UIImageView(frame: containerView.bounds)
//        imageView.contentMode = .scaleAspectFit
//        imageView.clipsToBounds = true
//        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        containerView.addSubview(imageView)
//        self.imageView = imageView
//
//        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
//            guard let data = data, error == nil, let image = UIImage(data: data) else {
//                print("❌ SNS Extension: Failed to load image: \(error?.localizedDescription ?? "Unknown error")")
//                return
//            }
//            DispatchQueue.main.async {
//                self?.imageView?.image = image
//                print("✅ SNS Extension: Image loaded successfully")
//
//                let state = SNSImageState(url: url.absoluteString)
//                if let encoded = try? JSONEncoder().encode(state),
//                   let defaults = UserDefaults(suiteName: SNSNotificationConstants.appGroupIdentifier) {
//                    defaults.set(encoded, forKey: StorageKeys.pendingImageState)
//                    defaults.synchronize()
//                    print("💾 SNS Extension: Image state saved to shared container")
//                } else {
//                    print("❌ SNS Extension: Failed to save image state")
//                }
//            }
//        }.resume()
//    }
//
//    private func saveFallbackVideoOrImageState(from userInfo: [AnyHashable: Any]) {
//        print("💾 SNS Extension: Saving fallback state from payload")
//
//        guard let defaults = UserDefaults(suiteName: SNSNotificationConstants.appGroupIdentifier) else {
//            print("❌ SNS Extension: No shared defaults")
//            return
//        }
//
//        if let videoURL = userInfo["video_url"] as? String {
//            let currentTime = userInfo["video_current_time"] as? Double ?? 0
//            let isPlaying = userInfo["video_is_playing"] as? Bool ?? true
//
//            let videoState = SNSVideoState(url: videoURL, currentTime: currentTime, isPlaying: isPlaying)
//            if let data = try? JSONEncoder().encode(videoState) {
//                defaults.set(data, forKey: StorageKeys.pendingVideoState)
//                defaults.synchronize()
//                print("✅ SNS Extension: Fallback video state saved")
//            }
//        }
//
//        if let imageURL = userInfo["image_url"] as? String {
//            let imageState = SNSImageState(url: imageURL)
//            if let data = try? JSONEncoder().encode(imageState) {
//                defaults.set(data, forKey: StorageKeys.pendingImageState)
//                defaults.synchronize()
//                print("✅ SNS Extension: Fallback image state saved")
//            }
//        }
//    }
//
//    private func hideFullscreenButton(in view: UIView) {
//        for subview in view.subviews {
//            if let button = subview as? UIButton {
//                let hasSmallImageData = button.currentImage?.pngData()?.count ?? Int.max < 5000
//                let hasFullscreenAccessibility = button.accessibilityLabel?.lowercased().contains("full") == true
//
//                if hasSmallImageData || hasFullscreenAccessibility {
//                    button.isHidden = true
//                    print("🔧 SNS Extension: Hidden potential fullscreen button")
//                }
//            }
//            hideFullscreenButton(in: subview)
//        }
//    }
//
//    private func cleanup() {
//        print("🧹 SNS Extension: Cleaning up previous media")
//
//        videoStateTimer?.invalidate()
//        videoStateTimer = nil
//
//        if let timeObserver = timeObserver,
//           let player = playerController?.player {
//            player.removeTimeObserver(timeObserver)
//            self.timeObserver = nil
//        }
//
//        imageView?.removeFromSuperview()
//
//        if let playerController = playerController {
//            playerController.view.removeFromSuperview()
//            playerController.removeFromParent()
//        }
//
//        imageView = nil
//        playerController = nil
//        currentVideoURL = nil
//        hasPlayedVideo = false
//    }
//
//    deinit {
//        cleanup()
//        print("🔧 SNS Extension Helper: Deinitialized")
//    }
//}


