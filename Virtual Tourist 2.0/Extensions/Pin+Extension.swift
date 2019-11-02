//
//  Pin+Extension.swift
//  Virtual Tourist 2.0
//
//  Created by Abdullah AlBargi on 01/11/2019.
//  Copyright © 2019 Abdullah AlBargi. All rights reserved.
//

import Foundation
import CoreData
import MapKit

extension Pin: MKAnnotation {
    public var coordinate: CLLocationCoordinate2D {
        return .init(latitude: .init(latitude), longitude: .init(longitude))
    }
}

