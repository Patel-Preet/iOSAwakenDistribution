//
//  SNSLocationManager.swift
//  SNSNotificationSDK
//
//  Created by Awaken Mobile on 21/7/2025.
//


//image and video both working
import CoreLocation

final class SNSLocationManager: NSObject, CLLocationManagerDelegate {
    
    static let shared = SNSLocationManager()
    private let locationManager = CLLocationManager()
    
    func startLocationUpdates() {
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        SNSNotificationManager.shared.updateDeviceLocation(latest.coordinate)
    }
}
