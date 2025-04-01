//
//  FetchPlaceImagesUseCase.swift
//  SeoulMate
//
//  Created by 박성근 on 4/2/25.
//

import Foundation
import Combine

protocol FetchPlaceImagesUseCaseProtocol {
  func execute(placeId: String, maxSize: CGSize) -> AnyPublisher<[PlaceImage], Error>
  func executeForFirstImage(placeId: String, maxSize: CGSize) -> AnyPublisher<PlaceImage?, Error>
}

final class FetchPlaceImagesUseCase: FetchPlaceImagesUseCaseProtocol {
  private let repository: PlaceImageRepositoryProtocol
  
  init(repository: PlaceImageRepositoryProtocol) {
    self.repository = repository
  }
  
  func execute(placeId: String, maxSize: CGSize) -> AnyPublisher<[PlaceImage], Error> {
    return repository.fetchPlaceImages(placeId: placeId, maxSize: maxSize)
  }
  
  func executeForFirstImage(placeId: String, maxSize: CGSize) -> AnyPublisher<PlaceImage?, Error> {
    return repository.fetchPlaceFirstImage(placeId: placeId, maxSize: maxSize)
  }
}
