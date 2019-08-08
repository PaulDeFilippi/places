//
//  LocationManager.swift
//  places
//
//  Created by Paul Defilippi on 8/7/19.
//  Copyright © 2019 Paul Defilippi. All rights reserved.
//

import Foundation
import MapKit

class LocationManager: NSObject, CLLocationManagerDelegate {
    
    var locationManager = CLLocationManager()
    
    var onLocationUpdate: ((CLLocation) -> Void)?
    
    func start(completionHandler: @escaping (CLLocation) -> Void) {
        locationManager.requestWhenInUseAuthorization()
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 50.0
        locationManager.delegate = self
        
        locationManager.startUpdatingLocation()
        
        onLocationUpdate = completionHandler
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        
        onLocationUpdate?(newLocation)
        
        
    }
    
}

