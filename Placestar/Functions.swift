//
//  Functions.swift
//  Placestar
//
//  Created by Felix Lösing on 03.07.15.
//  Copyright (c) 2015 Felix Lösing. All rights reserved.
//

import Foundation
import Dispatch


//free function handling delay to close HUD
func afterDelay(seconds: Double, closure: () -> ()) {
    
    let when = dispatch_time(DISPATCH_TIME_NOW, Int64(seconds * Double(NSEC_PER_SEC)))
    
    dispatch_after(when, dispatch_get_main_queue(), closure)
    
}

let applicationDocumentsDirectory: String = {
    let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
    return paths[0]
}()


