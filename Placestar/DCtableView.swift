//
//  DCtableView.swift
//  Placestar
//
//  Created by Felix Loesing on 28.04.2016.
//  Copyright (c) 2016 Felix Lösing. All rights reserved.
//

import Foundation
import UIKit

class DCtableView: UITableView, UITableViewDelegate {

     override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        if (point.y<0){
            return nil
        }
        return hitView
    }
    
}
