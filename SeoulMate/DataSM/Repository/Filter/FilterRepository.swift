//
//  FilterRepository.swift
//  SeoulMate
//
//  Created by 박성근 on 5/3/25.
//

import Foundation
import Combine

final class FilterRepository: FilterRepositoryProtocol {
  private let userService: UserServiceProtocol
  
  init(userService: UserServiceProtocol) {
    self.userService = userService
  }
  
  func getFilterData() -> AnyPublisher<FilterData?, NetworkError> {
    return userService.getProfile()
      .map { profile in
        return FilterData(
          companion: profile.companion,
          purposes: profile.purposes,
          userId: nil
        )
      }
      .eraseToAnyPublisher()
  }
  
  func saveFilterData(_ data: FilterData) -> AnyPublisher<Void, NetworkError> {
    return userService.getProfile()
      .flatMap { [weak self] profile -> AnyPublisher<Void, NetworkError> in
        guard let self = self else {
          return Fail(error: NetworkError.unknown(NSError()))
            .eraseToAnyPublisher()
        }
        
        return self.userService.updateProfile(
          userName: profile.userName,
          birthYear: profile.birthYear,
          companion: data.companion ?? "",
          purposes: data.purposes
        )
        .eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }
  
  func createFilterData(_ data: FilterData) -> AnyPublisher<FilterData, NetworkError> {
    return saveFilterData(data)
      .map { _ in data }
      .eraseToAnyPublisher()
  }
}
