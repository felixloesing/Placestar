//
//  LocationDetailsViewController.swift
//  Placestar
//
//  Created by Felix Lösing on 16.06.15.
//  Copyright (c) 2020 Felix Lösing. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import CoreData
import MapKit

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
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
    @IBOutlet weak var favButton: UIBarButtonItem!
    
    var managedObjectContext: NSManagedObjectContext! = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext
    
    var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var placemark : CLPlacemark?
    
    var descriptionText = NSLocalizedString("enter-name-here", value: "enter name here…", comment: "")
    var categoryName = NSLocalizedString("no-category", value: "No Category", comment: "")
    
    var date = Date()
    
    var observer: AnyObject!
    
    var favoriteToSave: Bool = false
    
    //image
    var image:UIImage?
    
    //Edit Location
    var locationToEdit: Location? {
        didSet {
            if let location = locationToEdit {
                if location.locationDescription == "" {
                    descriptionText = NSLocalizedString("enter-name-here", value: "enter name here…", comment: "")
                } else {
                    descriptionText = location.locationDescription
                }
                categoryName = location.category
                date = location.date as Date
                coordinate = CLLocationCoordinate2DMake(location.latitude, location.longitude)
                placemark = location.placemark
                favoriteToSave = location.favorite
                
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        descriptionTextView.delegate = self

        if let location = locationToEdit {
            title = ""
            
            if location.hasPhoto {
                if let image = location.photoImage {
                    showImage(image)
                    self.tableView.contentInset = UIEdgeInsets.init(top: -36, left: 0, bottom: 0, right: 0)
                }
            }
            
            let region = MKCoordinateRegion.init(center: CLLocationCoordinate2DMake(location.latitude, location.longitude), latitudinalMeters: 1000, longitudinalMeters: 1000)
            mapView.setRegion(mapView.regionThatFits(region), animated: true)
            let pinLocation = CLLocationCoordinate2DMake(location.latitude, location.longitude)
            // Drop a pin
            let dropPin = MKPointAnnotation()
            dropPin.coordinate = pinLocation
            mapView.addAnnotation(dropPin)
            
            if location.favorite == true {
                favButton.image = UIImage(systemName: "star.fill")
                favoriteToSave = true
            } else {
                favButton.image = UIImage(systemName: "star")
                favoriteToSave = false
            }
            

        } else {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
            
            let saveBarButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(done))
            let font = UIFont.boldSystemFont(ofSize: UIFont.labelFontSize)
            saveBarButton.setTitleTextAttributes([NSAttributedString.Key.font:font], for: .normal)
            
            
            navigationItem.rightBarButtonItem = saveBarButton
        }
        
        
        descriptionTextView.text = descriptionText
        categoryLabel.text = categoryName
        
        longitudeLabel.text = String(format: "%.8f", coordinate.longitude)
        latitudeLabel.text = String(format: "%.8f", coordinate.latitude)
        
        let region = MKCoordinateRegion.init(center: CLLocationCoordinate2DMake(coordinate.latitude, coordinate.longitude), latitudinalMeters: 1000, longitudinalMeters: 1000)
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
        
        //mapView tap recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.didTapMap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
    }
    
    //dismiss view by overdragging table view
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        /*
        if locationToEdit != nil {
        
            if (scrollView.contentOffset.y <= -120) {
                dismiss(animated: true, completion: nil)
            }
            
        */
    }
    
    @objc func cancelTapped() {
        self.performSegue(withIdentifier: "unwindToPlacestar", sender: self)
    }
    
    //open Apple Maps App when mapView is tapped
    @objc func didTapMap(_ sender: UITapGestureRecognizer) {
        
        let alert = UIAlertController(title: NSLocalizedString("open-maps", value: "Open Maps", comment: ""), message: NSLocalizedString("open-maps-prompt", value: "Do you want to open the Maps App?", comment: ""), preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", value: "Cancel", comment: ""), style: UIAlertAction.Style.cancel, handler: nil))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("yes", value: "Yes", comment: ""), style: UIAlertAction.Style.default, handler: { action in
            
            if let location = self.locationToEdit {
                let regionDistance:CLLocationDistance = 10000
                let coordinates = CLLocationCoordinate2DMake(location.latitude, location.longitude)
                let regionSpan = MKCoordinateRegion.init(center: coordinates, latitudinalMeters: regionDistance, longitudinalMeters: regionDistance)
                let options = [
                    MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
                    MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
                ]
                let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
                let mapItem = MKMapItem(placemark: placemark)
                mapItem.name = self.descriptionText
                mapItem.openInMaps(launchOptions: options)
            }
            
        }))
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if descriptionTextView.text == NSLocalizedString("enter-name-here", value: "enter name here…", comment: "") {
            descriptionTextView.font = UIFont.italicSystemFont(ofSize: descriptionTextView.font!.pointSize)
            descriptionTextView.textColor = UIColor(named: "TextLight")
        } else {
            descriptionTextView.font = UIFont.boldSystemFont(ofSize: descriptionTextView.font!.pointSize)
            descriptionTextView.textColor = UIColor(named: "TextDark")
        }
    }
    
    
    deinit {
        print("*** deinit \(self)")
        //print(observer)
        if observer != nil {
            NotificationCenter.default.removeObserver(observer as Any)
            print("*** deleted observer")
        }
    }
    

    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        descriptionTextView.frame.size.width = view.frame.size.width - 30
    }
    
    @objc func dismissKeyboard(_ gestureReconizer: UIGestureRecognizer) {
        //create indexpath from CGpoint value of the tap
        let point = gestureReconizer.location(in: tableView)
        let indexPath = tableView.indexPathForRow(at: point)
        
        //dismiss keyboard if tap happend outside of first cell
        if indexPath != nil && (indexPath! as NSIndexPath).section == 0 && (indexPath! as NSIndexPath).row == 0 {
            return
        } else {
            descriptionTextView.resignFirstResponder()
        }
    }
    
    func stringFromPlacemark(_ placemark: CLPlacemark) -> String {
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
    
    func formatDate(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }
    
    @IBAction func done() {
        
        if var topController = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
        }
        
        saveData()
        
        afterDelay(0.0, closure: { () -> () in
            //self.dismissViewControllerAnimated(true, completion: nil)
            self.performSegue(withIdentifier: "unwindToPlacestar", sender: self)
            
            //var vc = UIViewController = self.storyboard!.instantiateViewControllerWithIdentifier("mainView")
            
            //self.presentViewController(vc, animated: true, completion: nil)
            
        })
    }
    
    func saveData() {
        
        if descriptionText == NSLocalizedString("enter-name-here", value: "enter name here…", comment: "") {
            descriptionText = ""
            descriptionTextView.text = ""
        }
        
        if descriptionTextView.text == NSLocalizedString("enter-name-here", value: "enter name here…", comment: "") {
            descriptionText = ""
            descriptionTextView.text = ""
        }
        print("Description: \(descriptionText)")
        
        let location: Location
        
        if let tmp = locationToEdit {
            //hudView.text = "updated"
            location = tmp
        } else {
            let hudView = HudView.hudInView((UIApplication.shared.windows.first { $0.isKeyWindow }?.subviews.last)!, animated: true)
            hudView.text = "Tagged"
            //create CoreData Location object
            location = NSEntityDescription.insertNewObject(forEntityName: "Location", into: managedObjectContext) as! Location
            
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
                location.photoID = Location.nextPhotoID() as NSNumber?
            }
            
            if let data = image.jpegData(compressionQuality: 0.6) {
                
                do {
                    try data.write(to: URL(fileURLWithPath: location.photoPath), options: .atomic)
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
        
    }
    
    // get destination controller after save and update annotations on map
    
    func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "unwindToPlacestar" {
            let navController = segue.destination as? UINavigationController
            
            if let destinationViewController = navController?.topViewController as? ViewController {
                destinationViewController.updateLocations()
            }
        }
    }
    
    @IBAction func cancel() {
        dismiss(animated: true, completion: nil)
        performSegue(withIdentifier: "backHome", sender: nil)
    }
    
    @IBAction func toggleFavorite(_ sender: UIBarButtonItem) {
        if let location = locationToEdit {
            if location.favorite == true {
                location.favorite = false
                favoriteToSave = false
                favButton.image = UIImage(systemName: "star")
            } else {
                location.favorite = true
                favoriteToSave = true
                favButton.image = UIImage(systemName: "star.fill")
            }
            // Save change to database
            saveData()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PickCategory" {
            let controller = segue.destination as! CategoryPickerViewController
            controller.selectedCategoryName = categoryName
            
            let indexPath = IndexPath(row: 1, section: 1)
            tableView.deselectRow(at: indexPath, animated: true)
        } else if segue.identifier == "backHome" {
            //let controller = segue.destinationViewController as! ViewController
            //controller.managedObjectContext = managedObjectContext
        } else if segue.identifier == "unwindToPlacestar" {
            print("updated locations")
            let controller = segue.destination as! ViewController
            controller.reloadData()
        }
    }
    
    @IBAction func categoryPickerDidPickCategory(_ segue: UIStoryboardSegue) {
        let controller = segue.source as! CategoryPickerViewController
        
        categoryName = controller.selectedCategoryName
        categoryLabel.text = categoryName
    }
    
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        switch ((indexPath as NSIndexPath).section, (indexPath as NSIndexPath).row) {
        case (0, 0):
            return imageView.isHidden ? 44 : UIScreen.main.bounds.size.width + 2

            
        case (1, 0):
            return 88
            
        case (1, 2):
            return 220
            
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
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if (indexPath as NSIndexPath).section == 0 || (indexPath as NSIndexPath).section == 1 {
            return indexPath
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).section == 1 && (indexPath as NSIndexPath).row == 0 {
            descriptionTextView.becomeFirstResponder()
        } else if (indexPath as NSIndexPath).section == 0 && (indexPath as NSIndexPath).row == 0 {
            tableView.deselectRow(at: indexPath, animated: true)
            pickPhoto()
        }
    }
    
    func listenForBackgroundNotification() {
        observer = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: OperationQueue.main) { [weak self] _ in
            
            if let strongSelf = self {
            
                if strongSelf.presentedViewController != nil {
                    strongSelf.dismiss(animated: false, completion: nil)
                }
            
                strongSelf.descriptionTextView.resignFirstResponder()
            }
        }
    }
    
}

extension LocationDetailsViewController: UITextViewDelegate {
    
    
    //saving text to descriptionText
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        //make textview single-lined and hide keyboard with done button
        if(text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        
        descriptionText = (textView.text as NSString).replacingCharacters(in: range, with: text)

        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        descriptionText = textView.text
        
        if descriptionTextView.text == "" {
            descriptionTextView.font = UIFont.italicSystemFont(ofSize: descriptionTextView.font!.pointSize)
            descriptionTextView.textColor = UIColor(named: "TextLight")
            descriptionTextView.text = NSLocalizedString("enter-name-here", value: "enter name here…", comment: "")
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        //make textview visible above keyboard with animation
        
        if imageView.image != nil {
            UIView.animate(withDuration: 0.2) {
                self.tableView.contentOffset.y = 200
                
            }
        }
        
        descriptionTextView.font = UIFont.boldSystemFont(ofSize: descriptionTextView.font!.pointSize)
        descriptionTextView.textColor = UIColor(named: "TextDark")
        
        if textView.text == NSLocalizedString("enter-name-here", value: "enter name here…", comment: "") {
            textView.text = ""
        }
    }
}

extension LocationDetailsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func takePhotoWithCamera() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    func choosePhotoFromLibrary() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        
        image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.editedImage)] as? UIImage
        
        if let image = image {
            showImage(image)
        }
        tableView.reloadData()
        self.tableView.contentInset = UIEdgeInsets.init(top: -36, left: 0, bottom: 0, right: 0)
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func pickPhoto() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            showPhotoMenu()
        } else {
            choosePhotoFromLibrary()
        }
    }
    
    func showPhotoMenu() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("cancel", value: "Cancel", comment: ""), style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        
        let takePhotoAction = UIAlertAction(title: NSLocalizedString("take-photo", value: "Take Photo", comment: ""), style: .default, handler: { _ in self.takePhotoWithCamera() })
        
        alertController.addAction(takePhotoAction)
        
        let chooseFromLibraryAction = UIAlertAction(title: NSLocalizedString("choose-from-library", value: "Choose From Library", comment: ""), style: .default, handler: { _ in self.choosePhotoFromLibrary() })
        
        alertController.addAction(chooseFromLibraryAction)
        
        
        //option to save an existing image to camera roll
        if imageView.image != nil {
            
            let saveCurrentPhotoAction = UIAlertAction(title: NSLocalizedString("save-current-photo", value: "Save Current Photo", comment: ""), style: .default, handler: { _ in
                if let saveImage = self.imageView.image {
                
                UIImageWriteToSavedPhotosAlbum(saveImage, nil, nil, nil)
                
                let alert = UIAlertController(title: NSLocalizedString("success", value: "Success", comment: ""), message: NSLocalizedString("image-has-been-saved", value: "Image has been saved", comment: ""), preferredStyle: .alert)
                let action = UIAlertAction(title: "Okay", style: .default, handler: nil)
                alert.addAction(action)
                self.present(alert, animated: true, completion: nil)
                    
            } })
            alertController.addAction(saveCurrentPhotoAction)
            
        }
    
        present(alertController, animated: true, completion: nil)
    }
    
    func showImage(_ image: UIImage) {
        imageView.image = image
        imageView.isHidden = false
        imageView.frame = CGRect(x: 10, y: 10, width: 260, height: 260)
        addPhotoLabel.isHidden = true
    }
}



// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
