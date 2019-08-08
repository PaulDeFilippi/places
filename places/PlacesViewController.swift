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
        if isQueryPending == true {
            return
        }
        
        isQueryPending = true
        
        let clientId = URLQueryItem(name: "client_id", value: "DLW54SIWN4IOKR3QLXGA3FTWYEFN5QUPGIGA20BMBBFEAJDZ")
        let clientSecret = URLQueryItem(name: "client_secret", value: "GQBHKAX2UNQ5JJTSDXJMR4TOWIECICPMFXK4PG0F2DHSM2Z4")
        let version = URLQueryItem(name: "v", value: "20190401")
        let coordinate = URLQueryItem(name: "ll", value: "\(location.coordinate.latitude),\(location.coordinate.longitude)")
        let query = URLQueryItem(name: "query", value: "coffee")
        let intent = URLQueryItem(name: "intent", value: "browse")
        let radius = URLQueryItem(name: "radius", value: "250")
        
        var urlComponents = URLComponents(string: "https://api.foursquare.com/v2/venues/search")!
        urlComponents.queryItems = [clientId, clientSecret, version, coordinate, query, intent, radius]
        
        let task = URLSession.shared.dataTask(with: urlComponents.url!) { (data, response, error) in
            if let error = error {
                print("*** ERROR *** \(error.localizedDescription)")
                return
            }
            
            if data == nil || response == nil {
                print("*** SOMETHING WENT WRONG!!! ***")
                return
            }
            
            self.places.removeAll()
            
            do {
                let jsonData = try JSONSerialization.jsonObject(with: data!, options: [])
                
                // ****** Need to review the actual json response in the console to understand the layers of the branches ******
                
                if  let jsonObject = jsonData as? [String: Any],
                    let response   = jsonObject["response"] as? [String: Any],
                    let venues     = response["venues"] as? [[String: Any]] {
                    
                    for venue in venues {
                        if  let name             = venue["name"] as? String,
                            let location         = venue["location"] as? [String: Any],
                            let latitude         = location["lat"] as? Double,
                            let longitude        = location["lng"] as? Double,
                            let formattedAddress = location["formattedAddress"] as? [String] {
                            
                            self.places.append([
                                "name": name,
                                "address": formattedAddress.joined(separator: " "),
                                "latitude": latitude,
                                "longitude": longitude
                                
                            ])
                        }
                    }
                }
                
                self.places.sort(by: { (item1, item2) -> Bool in
                    let name1 = item1["name"] as! String
                    let name2 = item2["name"] as! String
                    
                    return name1 < name2
                })
                
                print(self.places)
                
            } catch {
                print("*** JSON ERROR *** \(error.localizedDescription)")
                return
            }
            
            self.isQueryPending = false
            DispatchQueue.main.async {
                self.updatePlaces()
                self.tableView?.reloadData()
            }
        }
        
        task.resume()
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

