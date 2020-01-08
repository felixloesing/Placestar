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
func afterDelay(_ seconds: Double, closure: @escaping () -> ()) {
    
    let when = DispatchTime.now() + Double(Int64(seconds * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
    
    DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
}

let applicationDocumentsDirectory: String = {
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
    return paths[0]
}()
