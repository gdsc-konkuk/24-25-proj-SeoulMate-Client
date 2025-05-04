//
//  GeneratePlacePromptUseCase.swift
//  SeoulMate
//
//  Created by 박성근 on 5/4/25.
//

import Foundation
import Combine

final class GeneratePlacePromptUseCase: GeneratePlacePromptUseCaseProtocol {
  private let placeRepository: PlaceRepositoryProtocol
  
  init(placeRepository: PlaceRepositoryProtocol) {
    self.placeRepository = placeRepository
  }
  
  func execute(placeId: String, purposes: [String]) -> AnyPublisher<PlacePromptResponse, NetworkError> {
    return placeRepository.generatePrompt(placeId: placeId, purposes: purposes)
  }
}
