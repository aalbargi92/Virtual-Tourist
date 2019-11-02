//
//  FlickerResponse.swift
//  Virtual Tourist
//
//  Created by Abdullah AlBargi on 29/10/2019.
//  Copyright © 2019 Abdullah AlBargi. All rights reserved.
//

import Foundation

struct FlickerResponse: Codable {
    let status: String
    let code: Int
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case status = "stat"
        case code
        case message
    }
}

extension FlickerResponse: LocalizedError {
    var errorDescription: String? {
        return message
    }
}
