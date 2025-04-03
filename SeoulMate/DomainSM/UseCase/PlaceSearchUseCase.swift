//
//  PlaceSearchUseCase.swift
//  SeoulMate
//
//  Created by 박성근 on 4/3/25.
//

import Foundation
import Combine
import CoreLocation
import GooglePlaces
import UIKit

protocol PlaceSearchUseCaseProtocol {
  func searchPlaces(query: String, region: CLLocationCoordinate2D?) -> AnyPublisher<[GMSAutocompletePrediction], Error>
  func getPlaceDetails(placeID: String, userLocation: CLLocation?) -> AnyPublisher<PlaceInfo, Error>
}

final class PlaceSearchUseCase: PlaceSearchUseCaseProtocol {
  
  private let repository: PlacesRepositoryProtocol
  
  init(repository: PlacesRepositoryProtocol) {
    self.repository = repository
  }
  
  func searchPlaces(query: String, region: CLLocationCoordinate2D? = nil) -> AnyPublisher<[GMSAutocompletePrediction], Error> {
    return repository.findAutocompletePredictions(query: query, region: region)
  }
  
  func getPlaceDetails(placeID: String, userLocation: CLLocation? = nil) -> AnyPublisher<PlaceInfo, Error> {
    // 입력 유효성 확인
    guard !placeID.isEmpty else {
      return Fail(error: NSError(
        domain: "PlaceSearchUseCase",
        code: -1,
        userInfo: [NSLocalizedDescriptionKey: "장소 ID가 비어있습니다"]
      )).eraseToAnyPublisher()
    }
    
    Logger.log(message: "UseCase: 장소 상세정보 요청 - placeID: \(placeID)")
    
    return repository.fetchPlaceDetails(placeID: placeID)
      .handleEvents(receiveOutput: { place in
        Logger.log(message: "UseCase: 장소 정보 조회 성공 - \(place.name ?? "이름 없음")")
      }, receiveCompletion: { completion in
        if case .failure(let error) = completion {
          Logger.log(message: "UseCase: 장소 정보 조회 실패 - \(error.localizedDescription)")
        }
      })
      .flatMap { [weak self] place -> AnyPublisher<PlaceInfo, Error> in
        guard let self = self else {
          return Fail(error: NSError(
            domain: "PlaceSearchUseCase",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Use case has been deallocated"]
          )).eraseToAnyPublisher()
        }
        
        return self.repository.getPlaceInfo(from: place, userLocation: userLocation)
          .handleEvents(receiveOutput: { placeInfo in
            Logger.log(message: "UseCase: PlaceInfo 변환 성공 - \(placeInfo.name)")
          }, receiveCompletion: { completion in
            if case .failure(let error) = completion {
              Logger.log(message: "UseCase: PlaceInfo 변환 실패 - \(error.localizedDescription)")
            }
          })
          .eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }
}
