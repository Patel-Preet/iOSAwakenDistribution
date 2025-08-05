//
//  SNSNotificationViewController.swift
//  SNSNotificationSDK
//
//  Created by Awaken Mobile on 21/7/2025.
//

//working with sns video on app launch

//import UIKit
//import UserNotifications
//import UserNotificationsUI
//
//open class SNSNotificationViewController: UIViewController, UNNotificationContentExtension {
//
//    public private(set) var helper: SNSNotificationExtensionHelper?
//
//    open override func viewDidLoad() {
//        super.viewDidLoad()
//        helper = SNSNotificationExtensionHelper(containerView: view)
//        preferredContentSize = CGSize(width: 0, height: 300)
//        print("🔧 SNS Base ViewController: Initialized")
//    }
//
//    // MARK: - UNNotificationContentExtension
//
//    open func didReceive(_ notification: UNNotification) {
//        print("🔔 SNS Base ViewController: Notification received")
//        helper?.render(notification: notification)
//        onNotificationReceived(notification)
//    }
//
//    open func didReceive(_ response: UNNotificationResponse, completionHandler: @escaping (UNNotificationContentExtensionResponseOption) -> Void) {
//        print("📲 SNS Base ViewController: Notification response received")
//        
//        // Save current video state through helper
//        helper?.onNotificationResponse(response)
//        
//        // Call partner's custom logic
//        onNotificationResponse(response)
//        
//        // Always dismiss and forward to main app
//        completionHandler(.dismissAndForwardAction)
//    }
//
//    // MARK: - Lifecycle Hooks
//
//    open override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        print("👋 SNS Base ViewController: View will disappear - saving state")
//        helper?.saveCurrentVideoState()
//    }
//
//    open override func viewDidDisappear(_ animated: Bool) {
//        super.viewDidDisappear(animated)
//        print("👋 SNS Base ViewController: View did disappear")
//    }
//
//    // MARK: - Partner Customization Points
//
//    /// Override this method to add custom logic when notification is received
//    /// - Parameter notification: The received notification
//    open func onNotificationReceived(_ notification: UNNotification) {
//        // Partners can override this for custom logic
//    }
//
//    /// Override this method to add custom logic when notification is tapped/responded to
//    /// - Parameter response: The notification response
//    open func onNotificationResponse(_ response: UNNotificationResponse) {
//        // Partners can override this for custom logic
//    }
//
//    // MARK: - Public Methods for Partners
//
//    /// Manually trigger video state saving (useful for custom UI interactions)
//    public func saveVideoState() {
//        helper?.saveCurrentVideoState()
//    }
//
//    /// Check if media is currently playing
//    public var isMediaPlaying: Bool {
//        // This could be extended to check the helper's internal state
//        return true // Simplified for now
//    }
//}



//image and video both working
import UIKit
import UserNotifications
import UserNotificationsUI

open class SNSNotificationViewController: UIViewController, UNNotificationContentExtension {

    public private(set) var helper: SNSNotificationExtensionHelper?

    open override func viewDidLoad() {
        super.viewDidLoad()
        helper = SNSNotificationExtensionHelper(containerView: view)
        preferredContentSize = CGSize(width: 0, height: 300)
        print("🔧 SNS Base ViewController: Initialized")
    }

    // MARK: - UNNotificationContentExtension

    open func didReceive(_ notification: UNNotification) {
        print("🔔 SNS Base ViewController: Notification received")
        helper?.render(notification: notification)
        onNotificationReceived(notification)
    }

    open func didReceive(_ response: UNNotificationResponse, completionHandler: @escaping (UNNotificationContentExtensionResponseOption) -> Void) {
        print("📲 SNS Base ViewController: Notification response received")
        
        // Save current video state through helper and fallback image / video
        helper?.onNotificationResponse(response)
        
        // Allow partners to inject custom logic
        onNotificationResponse(response)
        
        // Dismiss extension and forward action to main app
        completionHandler(.dismissAndForwardAction)
    }

    // MARK: - Lifecycle Hooks

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("👋 SNS Base ViewController: View will disappear - saving state")
        helper?.saveCurrentVideoState()
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("👋 SNS Base ViewController: View did disappear")
    }

    // MARK: - Partner Customization Points

    /// Override to react when notification received
    open func onNotificationReceived(_ notification: UNNotification) {
        // Partners may override
    }

    /// Override to react when notification tapped/responded
    open func onNotificationResponse(_ response: UNNotificationResponse) {
        // Partners may override
    }

    // MARK: - Public Interface for Partners

    public func saveVideoState() {
        helper?.saveCurrentVideoState()
    }

    public var isMediaPlaying: Bool {
        // Simplified: partners can extend this if needed
        return true
    }
}



