//
//  PlaceModels.swift
//  SeoulMate
//
//  Created by 박성근 on 5/3/25.
//

import Foundation

// MARK: - Place Models
struct PlaceResponse: Decodable {
  let id: String
  let address: String
  let image: String?
  let coordinate: CoordinateResponse
  let description: String?
}

struct CoordinateResponse: Decodable {
  let latitude: Double
  let longitude: Double
  
  enum CodingKeys: String, CodingKey {
    case latitude = "y"
    case longitude = "x"
  }
}

struct RecommendedPlace: Decodable {
  let placeId: String
  let description: String
  let reason: String
}

struct RecommendedPlacesResponse: Decodable {
  let places: [RecommendedPlace]
}

struct PlacePromptRequest: Encodable {
  let purposes: [String]
}

struct PlacePromptResponse: Decodable {
  let prompts: String
}
