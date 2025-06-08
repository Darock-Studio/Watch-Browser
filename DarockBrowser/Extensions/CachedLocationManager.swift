//
//  CachedLocationManager.swift
//  DarockBrowser
//
//  Created by Mark Chan on 2025/2/8.
//

import OSLog
import DarockUI

final class CachedLocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = CachedLocationManager()
    
    public var manager: CLLocationManager
    
    override init() {
        manager = CLLocationManager()
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    @AppStorage("CLMCachedLatitude") var cachedLatitude = 0.0
    @AppStorage("CLMCachedLongitude") var cachedLongitude = 0.0
    
    var updateCompletionHandler: () -> Void = {}
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue = locations.first else { return }
        cachedLatitude = locValue.coordinate.latitude
        cachedLongitude = locValue.coordinate.longitude
        updateCompletionHandler()
        os_log(.info, "Cached Location Updated: \(self.cachedLatitude), \(self.cachedLongitude)")
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        globalErrorHandler(error)
    }
    
    public func updateCache(withCompletionHandler completion: @escaping () -> Void = {}) {
        os_log(.info, "Updating Cached Location...")
        updateCompletionHandler = completion
        manager.requestLocation()
    }
    public func getCachedLocation() -> CLLocationCoordinate2D {
        .init(latitude: cachedLatitude, longitude: cachedLongitude)
    }
    public func getCachedLocation() -> CLLocation {
        .init(latitude: cachedLatitude, longitude: cachedLongitude)
    }
}
