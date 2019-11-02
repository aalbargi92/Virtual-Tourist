//
//  MapService.swift
//  Virtual Tourist
//
//  Created by Abdullah AlBargi on 30/10/2019.
//  Copyright © 2019 Abdullah AlBargi. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

struct Coordinate: Codable, Hashable {
    let latitude, longitude: Double
}

extension CLLocationCoordinate2D {
    init(_ coordinate: Coordinate) {
        self = .init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}

extension Coordinate {
    init(_ coordinate: CLLocationCoordinate2D) {
        self = .init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}

struct Zoom: Codable, Hashable {
    let latDelta, lonDelta: Double
}

extension MKCoordinateSpan {
    init(_ zoom: Zoom) {
        self = .init(latitudeDelta: .init(zoom.latDelta), longitudeDelta: .init(zoom.lonDelta))
    }
}

extension Zoom {
    init(_ span: MKCoordinateSpan) {
        self = .init(latDelta: span.latitudeDelta.magnitude, lonDelta: span.longitudeDelta.magnitude)
    }
}

struct MapLocation: Codable {
    let center: Coordinate
    let zoom: Zoom
}

class MapSerivce {
    static let mapCenterKey = "mapCenterKey"
    
    class func saveCenter(_ center: MapLocation) {
        do {
            let centerData = try JSONEncoder().encode(center)
            UserDefaults.standard.set(centerData, forKey: mapCenterKey)
            print("Center saved successfully")
        } catch  {
            print("Error saving center")
        }
    }
    
    class func getCenter() -> MapLocation? {
        do {
            if let data = UserDefaults.standard.object(forKey: mapCenterKey) as? Data {
                let center = try JSONDecoder().decode(MapLocation.self, from: data)
                print("Center retreived successfully")
                return center
            }
        } catch  {
            print("Error geetting center")
            return nil
        }
        
        return nil
    }
}
