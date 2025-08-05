//
//  SNSVideoState.swift
//  SNSNotificationSDK
//
//  Created by Awaken Mobile on 10/7/2025.
//

//image and video both working
import Foundation

public struct SNSVideoState: Codable {
    public let url: String
    public let currentTime: Double
    public let isPlaying: Bool
    public let timestamp: Date

    public init(url: String, currentTime: Double, isPlaying: Bool, timestamp: Date = Date()) {
        self.url = url
        self.currentTime = currentTime
        self.isPlaying = isPlaying
        self.timestamp = timestamp
    }
}
