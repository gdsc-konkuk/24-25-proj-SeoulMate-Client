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
  case getLikedPlaces
  case updateLikeStatus(placeId: String, like: Bool)
  
  var path: String {
    switch self {
    case .getRecommendedPlaces:
      return "/places"
    case .getLikedPlaces:
      return "/users/me/likes"
    case .updateLikeStatus:
      return "/users/me/likes"
    }
  }
  
  var method: HTTPMethod {
    switch self {
    case .getRecommendedPlaces:
      return .get
    case .getLikedPlaces:
      return .get
    case .updateLikeStatus:
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
    case .getLikedPlaces:
      return nil
    case .updateLikeStatus(let placeId, let like):
      return [
        "placeId": placeId,
        "like": like
      ]
    }
  }
}
