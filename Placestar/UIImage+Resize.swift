//
//  UIImage+Resize.swift
//  Placestar
//
//  Created by Felix Lösing on 26.04.16.
//  Copyright © 2016 Felix Lösing. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    
    func resizedImageWithBounds(_ bounds: CGSize) -> UIImage {
        
        let horizontalRatio = bounds.width / size.width
        let verticalRatio = bounds.height / size.height
        let ratio = min(horizontalRatio, verticalRatio)
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, true, 0)
        draw(in: CGRect(origin: CGPoint.zero, size: newSize))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}
