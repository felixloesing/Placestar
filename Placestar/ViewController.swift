//
//  ViewController.swift
//  Placestar
//
//  Created by Felix Lösing on 28.04.16.
//  Copyright © 2020 Felix Lösing. All rights reserved.
//

import UIKit
import MapKit
import CoreData
import CoreLocation

var tableView: UITableView!

class ViewController: UIViewController, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: DCtableView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var button: UIButton!
    
    let locationManager = CLLocationManager()
    
    var managedObjectContext: NSManagedObjectContext! = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext

    
    var alert: UIAlertController!
    
    var startup = true
    
    
    lazy var fetchedResultsController: NSFetchedResultsController<Location> = {
        let fetchRequest = NSFetchRequest<Location>()
        
        let entity = NSEntityDescription.entity(forEntityName: "Location", in: self.managedObjectContext)
        fetchRequest.entity = entity
        
        let sortDescriptor1 = NSSortDescriptor(key: "locationDescription", ascending: true)
        
        let sortDescriptor2 = NSSortDescriptor(key: "date", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor2, sortDescriptor1]
        
        fetchRequest.fetchBatchSize = 55
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: "Locations")
        
        return fetchedResultsController
    }()
    
    deinit {
        fetchedResultsController.delegate = nil
    }
    
    @IBAction func unwindToPlacestar (_ sender: UIStoryboardSegue){
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        performFetch()
        
        self.tableView.backgroundColor = UIColor.clear
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        tableView.bounces = true
        tableView.alwaysBounceVertical = true
        
        button.layer.cornerRadius = 35
        button.layer.masksToBounds = false
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowRadius = 1.2
        button.layer.shadowOffset = CGSize(width: 1, height: 1)
        
        //self.tableView.contentInset = UIEdgeInsets.init(top: self.mapView.frame.size.height+30, left: 0, bottom: 85, right: 0);
        
        let authStatus: CLAuthorizationStatus = CLLocationManager.authorizationStatus()
        
        if authStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            return
        } else if authStatus == .authorizedWhenInUse || authStatus == .authorizedAlways {
            updateLocations()
            showLocations()
        }
        
        //Map
        updateLocations()
        
        if !locations.isEmpty {
            showLocations()
        }

        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("appeared")
        
        //performFetch()
        //tableView.reloadData()

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.tableView.contentInset = UIEdgeInsets.init(top: self.mapView.frame.size.height-65, left: 0, bottom: 70, right: 0);
        self.tableView.contentOffset.y = -290
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        performFetch()
        tableView.reloadData()
        //showLocations()
        updateLocations()
        
        if startup == true {
            startup = false
            updateLocations()
            let region = regionForAnnotations(locations)
            mapView.setRegion(region, animated: false)
        }
        
    }
    
    func performFetch() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalCoreDataError(error)
        }
    }
    
    func reloadData() {
        performFetch()
        updateLocations()
        tableView.reloadData()
    }
    
    
    // MARK: - Table view data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath) as! LocationCell
        
        let location = fetchedResultsController.object(at: indexPath)
        
        //Configure the cell...
        cell.configureForLocation(location)
        let descriptionLabel = cell.viewWithTag(100) as! UILabel
        descriptionLabel.text = location.locationDescription
        cell.selectionStyle = .none
        
        //Display the timestamp of creation relative to the current day
        //Switches to years if more than 364 days ago
        let timestampLabel = cell.viewWithTag(234) as! UILabel
        let diffInDays = Calendar.current.dateComponents([.day], from: location.date, to: Date()).day
        var timestampString = ""
        if diffInDays! >= 365 {
            let calcYears:Int = diffInDays!/365
            timestampString += "\(calcYears) "
            if calcYears == 1 {
                timestampString += NSLocalizedString("year", value: "year", comment: "")
            } else {
                timestampString += NSLocalizedString("years", value: "years", comment: "")
            }
        } else {
            timestampString += "\(diffInDays!) "
            if diffInDays == 1 {
                timestampString += NSLocalizedString("day", value: "day", comment: "")
            } else {
                timestampString += NSLocalizedString("days", value: "days", comment: "")
            }
        }
        timestampLabel.text = timestampString
        
        let addressLabel = cell.viewWithTag(101) as! UILabel
        if let placemark = location.placemark {
            var addressText = ""
            if let s = placemark.subThoroughfare {
                addressText += s + " "
            }
            if let s = placemark.thoroughfare {
                addressText += s + ", "
            }
            if let s = placemark.locality {
                addressText += s
            }
            addressLabel.text = addressText
        } else {
            addressLabel.text = ""
        }
        
        return cell
    }
    

    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 57.0
    }
    
    
    
    // Override to support editing the table view.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            let location = fetchedResultsController.object(at: indexPath)
            
            managedObjectContext.delete(location)
            location.removePhotoFile()
            
            do {
                try managedObjectContext.save()
            } catch {
                fatalCoreDataError(error)
            }
            performFetch()
            tableView.reloadData()
            updateLocations()
        }
    }
 
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.name
    }
    
    
    // MARK: - Navigation
    

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print(segue)
        if segue.identifier == "EditLocation" {
            let navController = segue.destination as! UINavigationController
            let controller = navController.topViewController as! LocationDetailsViewController
            
            controller.managedObjectContext = managedObjectContext
            
            if let indexPath = tableView.indexPath(for: sender as! UITableViewCell) {
                let location = fetchedResultsController.object(at: indexPath)
                controller.locationToEdit = location
                
                
            }
 
 

        } else if segue.identifier == "add" {
            
            let controller = (segue.destination as! CurrentLocationViewController)
            controller.managedObjectContext = self.managedObjectContext
            
        } else if segue.identifier == "EditMapLocation" {
            let navigationController = segue.destination as! UINavigationController
            
            let controller = navigationController.topViewController as! LocationDetailsViewController
            
            controller.managedObjectContext = managedObjectContext
            
            let button = sender as! UIButton
            let location = locations[button.tag]
            controller.locationToEdit = location
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView.contentOffset.y < self.mapView.frame.size.height * -1 ) {
            scrollView .setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: self.mapView.frame.size.height * -1), animated: true)
        }
        
        if (scrollView.contentOffset.y <= -235) {
            var offset = scrollView.contentOffset
            offset.y = -235
            scrollView.contentOffset = offset
        }
    }


    // MARK: - FetchedResultController
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("*** controllerWillChangeContent")
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeObject anObject: Any, atIndexPath indexPath: IndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            print("*** NSFetchedResultsChangeInsert (object)")
            tableView.insertRows(at: [newIndexPath!], with: .fade)
            
        case .delete:
            print("*** NSFetchedResultsChangeDelete (object)")
            tableView.deleteRows(at: [indexPath!], with: .fade)
            
        case.update:
            print("*** NSFetchedResultsChangeUpdate (object)")
            
            if let cell = tableView.cellForRow(at: indexPath!) as? LocationCell {
                let location = controller.object(at: indexPath!) as! Location
                cell.configureForLocation(location)
            }
            
        case .move:
            print("*** NSFetchedResultsChangeMove (object)")
            tableView.deleteRows(at: [indexPath!], with: .fade)
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        @unknown default:
            fatalError()
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        
        switch type {
        case .insert:
            print("*** NSFetchedResultsChangeInsert (section)")
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
            
        case .delete:
            print("*** NSFetchedResultsChangeDelete (section)")
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        case .update:
            print("*** NSFetchedResultsChangeUpdate (section)")
            
        case .move:
            print("*** NSFetchedResultsChangeMove (section)")
        @unknown default:
            fatalError()
        }
        
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("*** controllerDidChangeContent")
        tableView.endUpdates()
        
    }
    
    
    // MARK: - Map
    
    var locations = [Location]()
    
    @IBAction func showUser() {
        let region = MKCoordinateRegion.init(center: mapView.userLocation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(mapView.regionThatFits(region), animated: true)
    }
    
    @IBAction func showLocations() {
        updateLocations()
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
                region = MKCoordinateRegion.init( center: mapView.userLocation.coordinate, latitudinalMeters: 1200, longitudinalMeters: 1200)
            case 1:
                let annotation = annotations[annotations.count - 1]
                region = MKCoordinateRegion.init(center: annotation.coordinate, latitudinalMeters: 1200, longitudinalMeters: 1200)
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
                
                let extraSpace = 1.45
                
                let span = MKCoordinateSpan(
                    latitudeDelta: abs(topLeftCoord.latitude - bottomRightCoord.latitude) * extraSpace,
                    longitudeDelta: abs(topLeftCoord.longitude - bottomRightCoord.longitude) * extraSpace)
                region = MKCoordinateRegion(center: center, span: span)
                
            }
            
            return mapView.regionThatFits(region)
    }

}

extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if #available(iOS 11.0, *) {
            
            guard annotation is Location else {
                return nil
            }
            
            let identifier = "Location"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as! MKMarkerAnnotationView?
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                
                annotationView?.isEnabled = true
                annotationView?.canShowCallout = true
                annotationView?.animatesWhenAdded = false
                annotationView?.markerTintColor = UIColor(red:0.13, green:0.82, blue:0.17, alpha:1.0)
                //                red: 0.32, green: 0.82, blue: 0.4, alpha: 1)
                annotationView?.displayPriority = MKFeatureDisplayPriority.required
                
                let rightButton = UIButton(type: .detailDisclosure)
                rightButton.addTarget(self, action: #selector(ViewController.showLocationDetails(_:)), for: .touchUpInside)
                
                annotationView?.rightCalloutAccessoryView = rightButton
                
            } else {
                annotationView?.annotation = annotation
            }
            
            let button = annotationView?.rightCalloutAccessoryView as! UIButton
            if let index = locations.firstIndex(of: annotation as! Location) {
                button.tag = index
            }
            
            return annotationView
            
            
        } else {
            // Fallback on earlier versions
            
            
            guard annotation is Location else {
                return nil
            }
            
            let identifier = "Location"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as! MKPinAnnotationView?
            
            if annotationView == nil {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                
                annotationView?.isEnabled = true
                annotationView?.canShowCallout = true
                annotationView?.animatesDrop = false
                annotationView?.pinTintColor = UIColor(red: 0.32, green: 0.82, blue: 0.4, alpha: 1)
                
                let rightButton = UIButton(type: .detailDisclosure)
                rightButton.addTarget(self, action: #selector(MapViewController.showLocationDetails(_:)), for: .touchUpInside)
                
                annotationView?.rightCalloutAccessoryView = rightButton
                
            } else {
                annotationView?.annotation = annotation
            }
            
            let button = annotationView?.rightCalloutAccessoryView as! UIButton
            if let index = locations.firstIndex(of: annotation as! Location) {
                button.tag = index
            }
            
            return annotationView
        }
    }
    
    @objc func showLocationDetails(_ sender: UIButton) {
        performSegue(withIdentifier: "EditMapLocation", sender: sender)
    }

}
