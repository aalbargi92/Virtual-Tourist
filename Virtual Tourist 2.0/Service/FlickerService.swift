//
//  FlickerService.swift
//  Virtual Tourist
//
//  Created by Abdullah AlBargi on 29/10/2019.
//  Copyright © 2019 Abdullah AlBargi. All rights reserved.
//

import Foundation

class FlickerService {
    
    enum Endpoints {
        static let apiKey = "b19a6f84e635eb5ae3be554fa60b1868"
        static let secret = "9ac01f8a5051dcf2"
        static let base = "https://www.flickr.com/services/rest/";
        
        case fetch(Int, Double, Double)
        
        var stringValue: String {
            switch self {
            case .fetch(let page, let lat, let lon): return Endpoints.base + "?method=flickr.photos.search&api_key=\(FlickerService.Endpoints.apiKey)" + "&lat=\(lat)" + "&lon=\(lon)" + "&page=\(page)&per_page=21&format=json&nojsoncallback=1"
            }
        }
        
        var url: URL! {
            return URL(string: stringValue)
        }
    }
    
    class func taskForGetRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil,  error)
                }
                return
            }
            
            let decoder = JSONDecoder()
            
            do {
                let response = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(response, nil)
                }
            } catch {
                do {
                    let errorResponse = try decoder.decode(FlickerResponse.self, from: data)
                    DispatchQueue.main.async {
                        completion(nil, errorResponse)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                }
            }
        }
        task.resume()
    }
    
    class func fetchImages(page: Int, latitude: Double, longitude: Double, completion: @escaping ([Photo], Error?) -> Void) {
        print(Endpoints.fetch(page, latitude, longitude).url.absoluteString)
        taskForGetRequest(url: Endpoints.fetch(page, latitude, longitude).url, responseType: PhotosResponse.self) { (response, error) in
            if let response = response {
                completion(response.photos.photo, nil)
            } else {
                completion([], error)
            }
        }
    }
}
