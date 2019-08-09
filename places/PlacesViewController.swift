//
//  PlacesViewController.swift
//  places
//
//  Created by Paul Defilippi on 7/19/19.
//  Copyright © 2019 Paul Defilippi. All rights reserved.
//

import UIKit
import MapKit

class PlacesViewController: UIViewController, MKMapViewDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var mapView: MKMapView?
    @IBOutlet var tableView: UITableView?
    
    var places = [[String: Any]]()
    
    var isQueryPending = false
    
    let locationManager = LocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView?.delegate = self
        
        tableView?.delegate = self
        tableView?.dataSource = self
        
        locationManager.start { (location) in
            self.centerMapView(on: location)
            self.queryFoursquare(with: location)
        }
        
    }
    
    func centerMapView(on location: CLLocation) {
        guard mapView != nil else { return }
        
        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 200, longitudinalMeters: 200)
        let adjustedRegion = mapView!.regionThatFits(region)
        
        mapView!.setRegion(adjustedRegion, animated: true)
    }
    
    func queryFoursquare(with location: CLLocation) {
        FoursquareAPI.shared.query(location: location, completionHandler: { places in
            self.places = places
            self.updatePlaces()
            self.tableView?.reloadData()
        })
    }
    
    func updatePlaces() {
        guard mapView != nil else { return }
        mapView!.removeAnnotations(mapView!.annotations)
        
        for place in places {
            
            if  let name      = place["name"] as? String,
                let latitude  = place["latitude"] as? CLLocationDegrees,
                let longitude = place["longitude"] as? CLLocationDegrees {
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                annotation.title = name
                
                mapView!.addAnnotation(annotation)
                
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKind(of: MKUserLocation.self) {
            return nil
        }
        
        var view = mapView.dequeueReusableAnnotationView(withIdentifier: "annotationView")
        
        if view == nil {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "annotationView")
            view!.canShowCallout = true
        } else {
            view!.annotation = annotation
        }
        
        return view
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return places.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cellIdentifier")
        
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cellIdentifier")
        }
        
        cell!.textLabel?.text = places[indexPath.row]["name"] as? String
        cell!.detailTextLabel?.text = places[indexPath.row]["address"] as? String
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard mapView != nil else { return }
        guard let tappedName = places[indexPath.row]["name"] as? String else { return }
        
        for annotation in mapView!.annotations {
            mapView!.deselectAnnotation(annotation, animated: false)
            
            if tappedName == annotation.title {
                mapView!.selectAnnotation(annotation, animated: true)
                mapView!.setCenter(annotation.coordinate, animated: true)
            }
            
        }
        
        
    }
}

