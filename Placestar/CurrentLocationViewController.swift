//
//  FirstViewController.swift
//  Placestar
//
//  Created by Felix Lösing on 09.06.15.
//  Copyright (c) 2015 Felix Lösing. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!

    
    var managedObjectContext: NSManagedObjectContext! = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    //location
    let locationManager = CLLocationManager()
    var location:CLLocation?
    var updatingLocation = false
    var lastLocationError: NSError?
    
    //(reverse) Geocoding
    let geocoder = CLGeocoder()
    var placemark: CLPlacemark?
    var performingReverseGeocoding = false
    var lastGeocodingError: NSError?
    
    //timer for 60 sec. timeout
    var timer: NSTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        print("CurrentLocationViewController1 *** \(managedObjectContext)")
        
        getLocation()
        
        tagButton.layer.cornerRadius = 15
        latitudeLabel.layer.cornerRadius = 15
        latitudeLabel.clipsToBounds = true
        longitudeLabel.layer.cornerRadius = 15
        longitudeLabel.clipsToBounds = true
        addressLabel.layer.cornerRadius = 15
        addressLabel.clipsToBounds = true
    }
    
    @IBAction func refreshButton(sender: AnyObject) {
        if updatingLocation {
            stopLocationManager()
        }
        getLocation()
    }
    func getLocation() {
        //checking location service settings
        let authStatus: CLAuthorizationStatus = CLLocationManager.authorizationStatus()
        
        if authStatus == .NotDetermined {
            locationManager.requestWhenInUseAuthorization()
            return
        }
        
        if authStatus == .Denied || authStatus == .Restricted {
            showLocationServicesDeniedAlert()
            return
        }
        
        //cancel location search
        if updatingLocation {
            stopLocationManager()
        } else {
            //reset and start
            location = nil
            lastLocationError = nil
            placemark = nil
            lastGeocodingError = nil
            startLocationManager()
        }
        updateLabels()
        configureGetButton()
    }
    
    func showLocationServicesDeniedAlert() {
        let alert = UIAlertController(title: "Location Service disabled", message: "Please enable Location Services in the Settings.", preferredStyle: UIAlertControllerStyle.Alert)
        
        let alertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
        alert.addAction(alertAction)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func updateLabels() {
        if let location = location {
            //updating labels
            latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
            longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
            tagButton.hidden = false
            messageLabel.text = ""
            
            //display adress or error message
            if let placemark = placemark {
                addressLabel.text = stringFromPlacemark(placemark)
            } else if performingReverseGeocoding {
                addressLabel.text = "Searching for Address…"
            } else if lastGeocodingError != nil {
                messageLabel.text = "Error finding Address"
            } else {
                addressLabel.text = "No Address Found"
            }
            
        } else {
            // reset labels
            latitudeLabel.text = ""
            longitudeLabel.text = ""
            addressLabel.text = ""
            tagButton.hidden = true
            
            //displaying error messages
            var statusMessage: String
            if let error = lastLocationError {
                if error.domain == kCLErrorDomain && error.code == CLError.Denied.rawValue {
                    statusMessage = "Location Services Disabled"
                } else {
                    statusMessage = "Error Getting Location"
                }
            } else if !CLLocationManager.locationServicesEnabled() {
                statusMessage = "Location Services Disabled"
            } else if updatingLocation {
                statusMessage = "Searching..."
            } else {
                statusMessage = "Tap 'Get My Location' to Start"
            }
            
            messageLabel.text = statusMessage
        }
    }
    
    func startLocationManager() {
        //configure location manager
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            updatingLocation = true
            
            timer = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: #selector(CurrentLocationViewController.didTimeOut), userInfo: nil, repeats: false)
        }
    }
    
    func stopLocationManager() {
        //disabling location manager
        if updatingLocation {
            if let timer = timer {
                timer.invalidate()
            }
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
            lastLocationError = nil
        }
    }
    
    
    func configureGetButton() {
        if updatingLocation {
            //getButton.setTitle("Stop", forState: .Normal)
            print("GetButton: *** Stop")
        } else {
            //getButton.setTitle("Get my Location", forState: .Normal)
            print("GetButton: *** Get my Location")
        }
    }
    
    
    
    func stringFromPlacemark(placemark: CLPlacemark) -> String {
        var line1 = ""
        
        if let s = placemark.subThoroughfare {
            line1 += s + " "
        }
        if let s = placemark.thoroughfare {
            line1 += s
        }
        
        var line2 = ""
        
        if let s = placemark.locality {
            line2 += s + " "
        }
        if let s = placemark.administrativeArea {
            line2 += s + " "
        }
        if let s = placemark.postalCode {
            line2 += s
        }
        
        return line1 + "\n" + line2
    }
    
    func didTimeOut() {
        print("*** time out ***")
        
        if location == nil {
            stopLocationManager()
            lastLocationError = NSError(domain: "PlacestarErrorDomain", code: 1, userInfo: nil)
            
            updateLabels()
            configureGetButton()
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("didFailwithError \(error)")
        if error.code == CLError.LocationUnknown.rawValue {
            return
        }
        lastLocationError = error
        stopLocationManager()
        updateLabels()
        configureGetButton()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
        print("didUpdateLocationLocations \(newLocation)")
        
        //checking if locastion is new (not older than 5 sec.)
        if newLocation.timestamp.timeIntervalSinceNow < -5 {
            return
        }
        //ignoring invalid location
        if newLocation.horizontalAccuracy < 0 {
            return
        }
        
        //distance between last and current location
        var distance = CLLocationDistance(DBL_MAX)
        if let location = location {
            distance = newLocation.distanceFromLocation(location)
        }
        
        //comparing accuracies & clearing errors and updating
        if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy {
            lastLocationError = nil
            location = newLocation
            updateLabels()
            
            //stop updating location if it meets requirements
            if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy {
                print("*** We're Done ***")
                stopLocationManager()
                configureGetButton()
                
                if distance > 0 {
                    performingReverseGeocoding = false
                }
            }
            
            if !performingReverseGeocoding {
                print("*** Going to geocode ***")
                
                performingReverseGeocoding = true
                
                geocoder.reverseGeocodeLocation(location!, completionHandler: { (placemarks, error) -> Void in
                    
                    self.lastGeocodingError = error
                    
                    self.lastGeocodingError = error
                    if error == nil, let p = placemarks where !p.isEmpty {
                        self.placemark = p.last!
                    } else {
                        self.placemark = nil
                    }
                    
                    self.performingReverseGeocoding = false
                    self.updateLabels()
                    self.configureGetButton()
                })
                
            } else if distance < 1.0 {
                //calculating time between locations
                let timeInterval = newLocation.timestamp.timeIntervalSinceDate(location!.timestamp)
                
                //stop after 10 sec. without better location
                if timeInterval > 10 {
                    print("*** force done ***")
                    stopLocationManager()
                    updateLabels()
                    configureGetButton()
                }
            }
        }
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "TagLocation" {
            let navigationController = segue.destinationViewController as! UINavigationController
            
            let controller = navigationController.topViewController as! LocationDetailsViewController
            
            print("CurrentLocationViewController *** \(managedObjectContext)")
            
            controller.coordinate = location!.coordinate
            controller.placemark = placemark
            controller.managedObjectContext = managedObjectContext
        }
    }

}

