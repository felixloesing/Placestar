//
//  CLPlacemark+Transformer.swift
//  Placestar
//
//  Created by Felix Loesing on 12/26/20.
//  Copyright © 2020 Felix Lösing. All rights reserved.
//

import Foundation
import CoreLocation

extension CLPlacemark: ValueTransforming {
    public static var valueTransformerName: NSValueTransformerName { .init("CLPlacemarkValueTransformer") }
}
