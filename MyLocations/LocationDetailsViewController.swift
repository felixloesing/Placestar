//
//  LocationDetailsViewController.swift
//  MyLocations
//
//  Created by Felix Lösing on 16.06.15.
//  Copyright (c) 2015 Felix Lösing. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

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
    
    var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var placemark : CLPlacemark?
    
    var descriptionText = ""
    var categoryName = "No Category"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        descriptionTextView.text = descriptionText
        categoryLabel.text = categoryName
        
        longitudeLabel.text = String(format: "%.8f", coordinate.longitude)
        latitudeLabel.text = String(format: "%.8f", coordinate.latitude)
        
        if let placemark = placemark {
            addressLabel.text = stringFromPlacemark(placemark)
        } else {
            addressLabel.text = "No Address found."
        }
        
        dateLabel.text = formatDate(NSDate())
        
        //dismiss keyboard with a tap outside the textview
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard:")
        gestureRecognizer.cancelsTouchesInView = false
        tableView.addGestureRecognizer(gestureRecognizer)
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
        return "\(placemark.subThoroughfare) \(placemark.thoroughfare), " + "\(placemark.locality), " + "\(placemark.administrativeArea) \(placemark.postalCode), " + "\(placemark.country)"
    }
    
    func formatDate(date: NSDate) -> String {
        return dateFormatter.stringFromDate(date)
    }
    
    @IBAction func done() {
        print("Description: \(descriptionText)")
        let hudView = HudView.hudInView(navigationController!.view, animated: true)
        hudView.text = "Tagged"
        //dismissViewControllerAnimated(true, completion: nil)
        
        afterDelay(0.6, closure: { () -> () in
            self.dismissViewControllerAnimated(true, completion: nil)
        })
    }
    
    @IBAction func cancel() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PickCategory" {
            let controller = segue.destinationViewController as! CategoryPickerViewController
            controller.selectedCategoryName = categoryName
        }
    }
    
    @IBAction func categoryPickerDidPickCategory(segue: UIStoryboardSegue) {
        let controller = segue.sourceViewController as! CategoryPickerViewController
        
        categoryName = controller.selectedCategoryName
        categoryLabel.text = categoryName
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 0 {
            return 88
        } else if indexPath.section == 2 && indexPath.row == 2 {
            
            //label width: screensize - 115px for address label && height: 10 000px space for text
            addressLabel.frame.size = CGSize(width: view.bounds.width - 115, height: 10000)
            
            // adjust size to fit text
            addressLabel.sizeToFit()
            //label could now be misplaced -> set 15px margin to the left
            addressLabel.frame.origin.x = view.bounds.width - addressLabel.frame.size.width - 15
            
            // 10px magin top/bottom
            return addressLabel.frame.size.height + 20
            
        } else {
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
        if indexPath.section == 0 && indexPath.row == 0 {
            descriptionTextView.becomeFirstResponder()
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


