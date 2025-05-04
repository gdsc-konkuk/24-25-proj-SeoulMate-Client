//
//  GeneratePlacePromptUseCaseProtocl.swift
//  SeoulMate
//
//  Created by 박성근 on 5/4/25.
//

import Foundation
import Combine

protocol GeneratePlacePromptUseCaseProtocol {
  func execute(placeId: String, purposes: [String]) -> AnyPublisher<PlacePromptResponse, NetworkError>
}
