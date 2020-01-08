//
//  Location.swift
//  Placestar
//
//  Created by Felix Lösing on 14.09.15.
//  Copyright (c) 2015 Felix Lösing. All rights reserved.
//

import Foundation
import CoreData
import MapKit

class Location: NSManagedObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(latitude, longitude)
    }
    
    var title: String? {
        if locationDescription.isEmpty {
            return NSLocalizedString("(no-description)", value: "(No Description)", comment: "")
        } else {
            return locationDescription
        }
    }
    
    var subtitle: String? {
        return category
    }
    
    var photoPath: String {
        assert(photoID != nil, "No photo ID set")
        let filename = "Photo-\(photoID!.intValue).jpg"
        return (applicationDocumentsDirectory as NSString).appendingPathComponent(filename)
    }
    
    var photoImage: UIImage? {
        return UIImage(contentsOfFile: photoPath)
    }
    
    class func nextPhotoID() -> Int {
        let userDefaults = UserDefaults.standard
        let currentID = userDefaults.integer(forKey: "PhotoID")
        userDefaults.set(currentID + 1, forKey: "PhotoID")
        userDefaults.synchronize()
        return currentID
        
    }
    
    var hasPhoto: Bool {
        return photoID != nil
    }
    
    func removePhotoFile() {
        if hasPhoto {
            let path = photoPath
            
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: path) {
                do {
                    try fileManager.removeItem(atPath: path)
                } catch {
                    print("*** Error removing file \(error)")
                }
            }
        }
    }
}
