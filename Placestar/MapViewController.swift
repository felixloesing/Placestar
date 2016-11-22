//
//  MapViewController.swift
//  Placestar
//
//  Created by Felix Lösing on 20.04.16.
//  Copyright © 2016 Felix Lösing. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var managedObjectContext: NSManagedObjectContext! {
        didSet {
            NotificationCenter.default.addObserver(forName: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object:         self.managedObjectContext, queue: OperationQueue.main) { (notification) in
                if self.isViewLoaded {
                    self.updateLocations()
                }
            }
        }
    }


    var locations = [Location]()
    
    @IBAction func showUser() {
        let region = MKCoordinateRegionMakeWithDistance(mapView.userLocation.coordinate, 1000, 1000)
        mapView.setRegion(mapView.regionThatFits(region), animated: true)
    }
    
    @IBAction func showLocations() {
        let region = regionForAnnotations(locations)
        mapView.setRegion(region, animated: true)
    }
    
    func updateLocations() {
        mapView.removeAnnotations(locations)
        
        let entity = NSEntityDescription.entity(forEntityName: "Location", in: managedObjectContext)
        
        let fetchRequest = NSFetchRequest<Location>()
        fetchRequest.entity = entity
        
        locations = try! managedObjectContext.fetch(fetchRequest) 
        
        mapView.addAnnotations(locations)
    }
    
    func regionForAnnotations(_ annotations: [MKAnnotation])
        -> MKCoordinateRegion {
            var region: MKCoordinateRegion
            switch annotations.count { case 0:
                region = MKCoordinateRegionMakeWithDistance( mapView.userLocation.coordinate, 1000, 1000)
            case 1:
                let annotation = annotations[annotations.count - 1]
                region = MKCoordinateRegionMakeWithDistance(annotation.coordinate, 1000, 1000)
            default:
                var topLeftCoord = CLLocationCoordinate2D(latitude: -90,
                                                          longitude: 180)
                var bottomRightCoord = CLLocationCoordinate2D(latitude: 90, longitude: -180)
                
                for annotation in annotations {
                    topLeftCoord.latitude = max(topLeftCoord.latitude, annotation.coordinate.latitude)
                    topLeftCoord.longitude = min(topLeftCoord.longitude, annotation.coordinate.longitude)
                    bottomRightCoord.latitude = min(bottomRightCoord.latitude, annotation.coordinate.latitude)
                    bottomRightCoord.longitude = max(bottomRightCoord.longitude, annotation.coordinate.longitude)
                }
                let center = CLLocationCoordinate2D(latitude: topLeftCoord.latitude -
                    (topLeftCoord.latitude - bottomRightCoord.latitude) / 2, longitude: topLeftCoord.longitude -
                        (topLeftCoord.longitude - bottomRightCoord.longitude) / 2)
                
                let extraSpace = 1.1
                
                let span = MKCoordinateSpan(
                    latitudeDelta: abs(topLeftCoord.latitude - bottomRightCoord.latitude) * extraSpace,
                    longitudeDelta: abs(topLeftCoord.longitude - bottomRightCoord.longitude) * extraSpace)
                region = MKCoordinateRegion(center: center, span: span)
            
            }
            
            return mapView.regionThatFits(region)
    }
                                                     
                                                     
                                                     
                                                     
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateLocations()
        
        if !locations.isEmpty {
            showLocations()
        }
        // Do any additional setup after loading the view.
    }

}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is Location else {
            return nil
        }
        
        let identifier = "Location"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as! MKPinAnnotationView!
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            
            annotationView?.isEnabled = true
            annotationView?.canShowCallout = true
            annotationView?.animatesDrop = true
            annotationView?.pinTintColor = UIColor(red: 0.32, green: 0.82, blue: 0.4, alpha: 1)
            
            let rightButton = UIButton(type: .detailDisclosure)
            rightButton.addTarget(self, action: #selector(MapViewController.showLocationDetails(_:)), for: .touchUpInside)
            
            annotationView?.rightCalloutAccessoryView = rightButton
            
        } else {
            annotationView?.annotation = annotation
        }
        
        let button = annotationView?.rightCalloutAccessoryView as! UIButton
        if let index = locations.index(of: annotation as! Location) {
            button.tag = index
        }
        
        return annotationView
    }
    
    func showLocationDetails(_ sender: UIButton) {
        performSegue(withIdentifier: "EditLocation", sender: sender)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EditLocation" {
            let navigationController = segue.destination as! UINavigationController
            
            let controller = navigationController.topViewController as! LocationDetailsViewController
            
            controller.managedObjectContext = managedObjectContext
            
            let button = sender as! UIButton
            let location = locations[button.tag]
            controller.locationToEdit = location
        }
    }
    
}

extension MapViewController: UINavigationBarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
