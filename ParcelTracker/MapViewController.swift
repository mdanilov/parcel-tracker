//
//  MapViewController.swift
//  ParcelTracker
//
//  Created by Максим Данилов on 08/01/2019.
//  Copyright © 2019 Maxim Danilov. All rights reserved.
//

import Cocoa
import MapKit
import CoreLocation
import CoreFoundation

class MapViewController: NSViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    func initFromParcel(_ parcel: Parcel) {
        guard let events = parcel.status?.events else {
            return
        }
        
        for event in events {
            if (event.location != nil) {
                let geocoder = CLGeocoder()
                geocoder.geocodeAddressString(event.location!) { places, error in
                    if places != nil, let coordinate = places!.first?.location?.coordinate {
                        for place in places! {
                            print(event.location, place, places?.count)
                        }
                        
                        self.mapView.addAnnotation(MKPlacemark(coordinate: coordinate))
                    }
                }
            }
        }
    }
    
}
