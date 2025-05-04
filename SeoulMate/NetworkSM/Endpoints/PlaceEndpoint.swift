//
//  PlaceEndpoint.swift
//  SeoulMate
//
//  Created by 박성근 on 5/3/25.
//

import Foundation
import Alamofire

enum PlaceEndpoint: Endpoint {
  case getRecommendedPlaces(x: Double, y: Double)
  case generatePrompt(placeId: String, purposes: [String])
  
  var path: String {
    switch self {
    case .getRecommendedPlaces:
      return "/places"
    case .generatePrompt(let placeId, _):
      return "/places/\(placeId)"
    }
  }
  
  var method: HTTPMethod {
    switch self {
    case .getRecommendedPlaces:
      return .get
    case .generatePrompt:
      return .post
    }
  }
  
  var parameters: Parameters? {
    switch self {
    case .getRecommendedPlaces(let x, let y):
      return [
        "x": x,
        "y": y
      ]
      
    case .generatePrompt(_, let purposes):
      return [
        "purposes": purposes
      ]
    }
  }
}
