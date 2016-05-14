//
//  DCtableView.swift
//  Placestar
//
//  Created by DC on 28.04.2016.
//  Copyright (c) 2016 Felix Lösing. All rights reserved.
//

import Foundation
import UIKit

class DCtableView: UITableView, UITableViewDelegate {

     override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, withEvent: event)
        if (point.y<0){
            return nil
        }
        return hitView
    }
 
    
}
