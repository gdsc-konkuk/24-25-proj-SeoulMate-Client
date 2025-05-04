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
  func generatePrompt(placeId: String, purposes: [String]) -> AnyPublisher<PlacePromptResponse, NetworkError>
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
  
  func generatePrompt(placeId: String, purposes: [String]) -> AnyPublisher<PlacePromptResponse, NetworkError> {
    let endpoint = PlaceEndpoint.generatePrompt(placeId: placeId, purposes: purposes)
    return networkProvider.request(endpoint)
  }
}
