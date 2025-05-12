//
//  PlaceService.swift
//  SeoulMate
//
//  Created by 박성근 on 5/4/25.
//

import Foundation
import Combine

protocol PlaceServiceProtocol {
  func getRecommendedPlaces(x: Double, y: Double) -> AnyPublisher<RecommendedPlacesResponse, NetworkError>
  func getLikedPlaces() -> AnyPublisher<LikedPlacesResponse, NetworkError>
  func updateLikeStatus(placeId: String, like: Bool) -> AnyPublisher<EmptyResponse, NetworkError>
}

final class PlaceService: PlaceServiceProtocol {
  private let networkProvider: NetworkProviderProtocol
  
  init(networkProvider: NetworkProviderProtocol) {
    self.networkProvider = networkProvider
  }
  
  func getRecommendedPlaces(x: Double, y: Double) -> AnyPublisher<RecommendedPlacesResponse, NetworkError> {
    let endpoint = PlaceEndpoint.getRecommendedPlaces(x: x, y: y)
    return networkProvider.request(endpoint)
  }
  
  func getLikedPlaces() -> AnyPublisher<LikedPlacesResponse, NetworkError> {
    let endpoint = PlaceEndpoint.getLikedPlaces
    return networkProvider.request(endpoint)
  }
  
  func updateLikeStatus(placeId: String, like: Bool) -> AnyPublisher<EmptyResponse, NetworkError> {
    let endpoint = PlaceEndpoint.updateLikeStatus(placeId: placeId, like: like)
    return networkProvider.request(endpoint)
  }
}
