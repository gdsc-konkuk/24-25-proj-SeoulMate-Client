//
//  PlaceImageRepository.swift
//  SeoulMate
//
//  Created by 박성근 on 4/2/25.
//

import Foundation
import Combine
import UIKit

final class PlaceImageRepository: PlaceImageRepositoryProtocol {
  private let networkService: PlaceImageNetworkServiceProtocol
  
  init(networkService: PlaceImageNetworkServiceProtocol) {
    self.networkService = networkService
  }
  
  func fetchPlaceImages(placeId: String, maxSize: CGSize) -> AnyPublisher<[PlaceImage], Error> {
    return networkService.fetchPlaceImages(placeId: placeId, maxSize: maxSize)
      .map { dtos in
        return dtos.map { $0.toDomain() }
      }
      .eraseToAnyPublisher()
  }
  
  func fetchPlaceFirstImage(placeId: String, maxSize: CGSize) -> AnyPublisher<PlaceImage?, Error> {
    return networkService.fetchPlaceFirstImage(placeId: placeId, maxSize: maxSize)
      .map { dto in
        return dto?.toDomain()
      }
      .eraseToAnyPublisher()
  }
}
