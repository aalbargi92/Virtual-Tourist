//
//  ImageResponse.swift
//  Virtual Tourist
//
//  Created by Abdullah AlBargi on 29/10/2019.
//  Copyright © 2019 Abdullah AlBargi. All rights reserved.
//

import Foundation

struct ImageSizeResponse: Codable {
    let source: String
}

struct ImageSizesResponse: Codable {
    let size: [ImageSizeResponse]
}

struct GenericImageResponse: Codable {
    let sizes: ImageSizesResponse
}
