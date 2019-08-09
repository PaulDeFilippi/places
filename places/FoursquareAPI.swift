//
//  FoursquareAPI.swift
//  places
//
//  Created by Paul Defilippi on 8/7/19.
//  Copyright © 2019 Paul Defilippi. All rights reserved.
//

import Foundation
import MapKit

class FoursquareAPI {
    static let shared = FoursquareAPI()
    
    var isQueryPending = false
    
    private init() { }
    
    func query(location: CLLocation, completionHandler: @escaping ([[String: Any]]) -> Void) {
        
        if isQueryPending == true {
            return
        }
        
        isQueryPending = true
        
        var places = [[String: Any]]()
        
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
                            
                            places.append([
                                "name": name,
                                "address": formattedAddress.joined(separator: " "),
                                "latitude": latitude,
                                "longitude": longitude
                                
                                ])
                        }
                    }
                }
                
                places.sort(by: { (item1, item2) -> Bool in
                    let name1 = item1["name"] as! String
                    let name2 = item2["name"] as! String
                    
                    return name1 < name2
                })
                
                print(places)
                
            } catch {
                print("*** JSON ERROR *** \(error.localizedDescription)")
                return
            }
            
            self.isQueryPending = false
            DispatchQueue.main.async {
                completionHandler(places)
            }
        }
        
        task.resume()
        
    }
}
