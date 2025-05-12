//
//  PlaceRepositoryProtocol.swift
//  SeoulMate
//
//  Created by 박성근 on 5/4/25.
//

import Foundation
import Combine

protocol PlaceRepositoryProtocol {
  func getRecommendedPlaces(x: Double, y: Double) -> AnyPublisher<RecommendedPlacesResponse, NetworkError>
  func getLikedPlaces() -> AnyPublisher<LikedPlacesResponse, NetworkError>
  func updateLikeStatus(placeId: String, like: Bool) -> AnyPublisher<EmptyResponse, NetworkError>
}
