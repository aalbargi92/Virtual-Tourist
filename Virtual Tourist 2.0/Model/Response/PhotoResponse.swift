//
//  PhotoResponse.swift
//  Virtual Tourist
//
//  Created by Abdullah AlBargi on 29/10/2019.
//  Copyright © 2019 Abdullah AlBargi. All rights reserved.
//

import Foundation

struct Photo: Codable {
    let id, server, secret: String
    let farm: Int
    
    var url: URL! {
        return URL(string: "https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret)_s.jpg")
    }
}
