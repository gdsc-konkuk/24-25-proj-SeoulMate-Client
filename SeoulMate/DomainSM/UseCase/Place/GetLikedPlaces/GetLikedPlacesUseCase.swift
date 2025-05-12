//
//  GetLikedPlacesUseCase.swift
//  SeoulMate
//
//  Created by 박성근 on 5/4/25.
//

import Foundation
import Combine

final class GetLikedPlacesUseCase: GetLikedPlacesUseCaseProtocol {
  private let placeRepository: PlaceRepositoryProtocol
  
  init(placeRepository: PlaceRepositoryProtocol) {
    self.placeRepository = placeRepository
  }
  
  func execute() -> AnyPublisher<LikedPlacesResponse, NetworkError> {
    return placeRepository.getLikedPlaces()
  }
} 
