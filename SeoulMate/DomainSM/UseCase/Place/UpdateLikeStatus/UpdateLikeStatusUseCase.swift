//
//  UpdateLikeStatusUseCase.swift
//  SeoulMate
//
//  Created by 박성근 on 5/12/25.
//

import Foundation
import Combine

final class UpdateLikeStatusUseCase: UpdateLikeStatusUseCaseProtocol {
  private let placeRepository: PlaceRepositoryProtocol
  
  init(placeRepository: PlaceRepositoryProtocol) {
    self.placeRepository = placeRepository
  }
  
  func execute(placeId: String, like: Bool) -> AnyPublisher<EmptyResponse, NetworkError> {
    return placeRepository.updateLikeStatus(placeId: placeId, like: like)
  }
} 
