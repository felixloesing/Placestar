//
//  LocationDetailsViewController.swift
//  Placestar
//
//  Created by Felix Lösing on 16.06.15.
//  Copyright (c) 2015 Felix Lösing. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import CoreData
import MapKit

private let dateFormatter: NSDateFormatter = {
    let formatter = NSDateFormatter()
    formatter.dateStyle = .MediumStyle
    formatter.timeStyle = .ShortStyle
    print("dateFormatter created")
    return formatter
}()

class LocationDetailsViewController: UITableViewController {
    
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var addPhotoLabel: UILabel!
    
    @IBOutlet weak var mapView: MKMapView!
    
    
    var managedObjectContext: NSManagedObjectContext! = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var placemark : CLPlacemark?
    
    var descriptionText = ""
    var categoryName = NSLocalizedString("no-category", value: "No Category", comment: "")
    
    var date = NSDate()
    
    var observer: AnyObject!
    
    //image
    var image:UIImage?
    
    //Edit Location
    var locationToEdit: Location? {
        didSet {
            if let location = locationToEdit {
                descriptionText = location.locationDescription
                categoryName = location.category
                date = location.date
                coordinate = CLLocationCoordinate2DMake(location.latitude, location.longitude)
                placemark = location.placemark
                
                
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let location = locationToEdit {
            //title = "\(location.locationDescription)"
            title = ""
            
            if location.hasPhoto {
                if let image = location.photoImage {
                    showImage(image)
                    self.tableView.contentInset = UIEdgeInsetsMake(-36, 0, 0, 0)
                }
            }
            
            let region = MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2DMake(location.latitude, location.longitude), 1000, 1000)
            mapView.setRegion(mapView.regionThatFits(region), animated: true)
            let pinLocation = CLLocationCoordinate2DMake(location.latitude, location.longitude)
            // Drop a pin
            let dropPin = MKPointAnnotation()
            dropPin.coordinate = pinLocation
            mapView.addAnnotation(dropPin)
        }
        
        
        descriptionTextView.text = descriptionText
        categoryLabel.text = categoryName
        
        longitudeLabel.text = String(format: "%.8f", coordinate.longitude)
        latitudeLabel.text = String(format: "%.8f", coordinate.latitude)
        
        
        let region = MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2DMake(coordinate.latitude, coordinate.longitude), 1000, 1000)
        mapView.setRegion(mapView.regionThatFits(region), animated: true)
        
        let pinLocation = CLLocationCoordinate2DMake(coordinate.latitude, coordinate.longitude)
        // Drop a pin
        let dropPin = MKPointAnnotation()
        dropPin.coordinate = pinLocation
        mapView.addAnnotation(dropPin)
        
        if let placemark = placemark {
            print("++++ placemark: \(stringFromPlacemark(placemark))")
            addressLabel.text = stringFromPlacemark(placemark)
        } else {
            addressLabel.text = NSLocalizedString("no-address-found", value: "No Address found", comment: "")
        }
        
        dateLabel.text = formatDate(date)
        
        //dismiss keyboard with a tap outside the textview
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(LocationDetailsViewController.dismissKeyboard(_:)))
        gestureRecognizer.cancelsTouchesInView = false
        tableView.addGestureRecognizer(gestureRecognizer)
        tableView.backgroundView = nil
        tableView.backgroundColor = UIColor.whiteColor()
        
    }
    
    deinit {
        print("*** deinit \(self)")
        //print(observer)
        if observer != nil {
            NSNotificationCenter.defaultCenter().removeObserver(observer)
            print("*** deleted observer")
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        descriptionTextView.frame.size.width = view.frame.size.width - 30
    }
    
    func dismissKeyboard(gestureReconizer: UIGestureRecognizer) {
        //create indexpath from CGpoint value of the tap
        let point = gestureReconizer.locationInView(tableView)
        let indexPath = tableView.indexPathForRowAtPoint(point)
        
        //dismiss keyboard if tap happend outside of first cell
        if indexPath != nil && indexPath!.section == 0 && indexPath!.row == 0 {
            return
        } else {
            descriptionTextView.resignFirstResponder()
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
    
    func formatDate(date: NSDate) -> String {
        return dateFormatter.stringFromDate(date)
    }
    
    @IBAction func done() {
        print("Description: \(descriptionText)")
        
        let hudView = HudView.hudInView(navigationController!.view, animated: true)
        
        let location: Location
        
        if let tmp = locationToEdit {
            hudView.text = "updated"
            location = tmp
        } else {
            hudView.text = "Tagged"
            //create CoreData Location object
            location = NSEntityDescription.insertNewObjectForEntityForName("Location", inManagedObjectContext: managedObjectContext) as! Location
            
            location.photoID = nil
        }
        

        
        //set properties of Location object
        location.locationDescription = descriptionTextView.text
        location.category = categoryName
        location.longitude = coordinate.longitude
        location.latitude = coordinate.latitude
        location.date = date
        location.placemark = placemark
        
        //save image
        
        if let image = image {
            if !location.hasPhoto {
                location.photoID = Location.nextPhotoID()
            }
            
            if let data = UIImageJPEGRepresentation(image, 0.6) {
                
                do {
                    try data.writeToFile(location.photoPath, options: .DataWritingAtomic)
                } catch {
                    print("Error writing file: \(error)")
                }
            }
            
        }
        
        
        //saving / try catch for safety, save() can fail
        do {
            try managedObjectContext.save()
        } catch {
            fatalCoreDataError(error)
        }
        
        afterDelay(0.0, closure: { () -> () in
            self.dismissViewControllerAnimated(true, completion: nil)
        })
    }
    
    @IBAction func cancel() {
        dismissViewControllerAnimated(true, completion: nil)
        performSegueWithIdentifier("backHome", sender: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PickCategory" {
            let controller = segue.destinationViewController as! CategoryPickerViewController
            controller.selectedCategoryName = categoryName
        } else if segue.identifier == "backHome" {
            let controller = segue.destinationViewController as! ViewController
            controller.managedObjectContext = managedObjectContext
        }
    }
    
    @IBAction func categoryPickerDidPickCategory(segue: UIStoryboardSegue) {
        let controller = segue.sourceViewController as! CategoryPickerViewController
        
        categoryName = controller.selectedCategoryName
        categoryLabel.text = categoryName
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            return imageView.hidden ? 44 : UIScreen.mainScreen().bounds.size.width + 2

            
        case (1, 0):
            return 88
            
        case (1, 2):
            return 115
            
        case(2, 2):
            
            //label width: screensize - 115px for address label && height: 10 000px space for text
            addressLabel.frame.size = CGSize(width: view.bounds.width - 115, height: 10000)
            
            // adjust size to fit text
            addressLabel.sizeToFit()
            //label could now be misplaced -> set 15px margin to the left
            addressLabel.frame.origin.x = view.bounds.width - addressLabel.frame.size.width - 15
            
            // 10px magin top/bottom
            return addressLabel.frame.size.height + 20
 
        default:
            return 44
        }
    }
    
    
    //only first two sections are tapable
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if indexPath.section == 0 || indexPath.section == 1 {
            return indexPath
        } else {
            return nil
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 1 && indexPath.row == 0 {
            descriptionTextView.becomeFirstResponder()
        } else if indexPath.section == 0 && indexPath.row == 0 {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            pickPhoto()
        }
    }
    
    func listenForBackgroundNotification() {
        observer = NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidEnterBackgroundNotification, object: nil, queue: NSOperationQueue.mainQueue()) { [weak self] _ in
            
            if let strongSelf = self {
            
                if strongSelf.presentedViewController != nil {
                    strongSelf.dismissViewControllerAnimated(false, completion: nil)
                }
            
                strongSelf.descriptionTextView.resignFirstResponder()
            }
        }
    }
    
}

extension LocationDetailsViewController: UITextViewDelegate {
    
    //saving text to descriptionText
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        descriptionText = (textView.text as NSString).stringByReplacingCharactersInRange(range, withString: text)
        return true
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        descriptionText = textView.text
    }
}

extension LocationDetailsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func takePhotoWithCamera() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .Camera
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func choosePhotoFromLibrary() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .PhotoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        image = info[UIImagePickerControllerEditedImage] as? UIImage
        
        if let image = image {
            showImage(image)
        }
        tableView.reloadData()
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func pickPhoto() {
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
            showPhotoMenu()
        } else {
            choosePhotoFromLibrary()
        }
    }
    
    func showPhotoMenu() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", value: "Cancel", comment: ""), style: .Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: NSLocalizedString("camera", value: "Camera", comment: ""), style: .Default, handler: { _ in self.takePhotoWithCamera()}))
        alert.addAction(UIAlertAction(title: NSLocalizedString("photo-library", value: "Photo Library", comment: ""), style: .Default, handler: { _ in self.choosePhotoFromLibrary()}))
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func showImage(image: UIImage) {
        imageView.image = image
        imageView.hidden = false
        imageView.frame = CGRect(x: 10, y: 10, width: 260, height: 260)
        addPhotoLabel.hidden = true
    }
}


