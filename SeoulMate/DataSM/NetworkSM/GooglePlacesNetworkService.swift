//
//  GooglePlacesNetworkService.swift
//  SeoulMate
//
//  Created by 박성근 on 4/3/25.
//

import Foundation
import GooglePlaces
import Combine
import CoreLocation
import UIKit

protocol GooglePlacesNetworkServiceProtocol {
  // 자동완성 검색
  func findAutocompletePredictions(query: String, filter: GMSAutocompleteFilter) -> AnyPublisher<[GMSAutocompletePrediction], Error>
  
  // 장소 상세 정보 가져오기
  func fetchPlaceDetails(placeID: String, fields: GMSPlaceField) -> AnyPublisher<GMSPlace, Error>
}

final class GooglePlacesNetworkService: GooglePlacesNetworkServiceProtocol {
  private let placesClient: GMSPlacesClient
  
  init(placesClient: GMSPlacesClient = GMSPlacesClient.shared()) {
    self.placesClient = placesClient
  }
  
  func findAutocompletePredictions(query: String, filter: GMSAutocompleteFilter) -> AnyPublisher<[GMSAutocompletePrediction], Error> {
    return Future<[GMSAutocompletePrediction], Error> { [weak self] promise in
      guard let self = self else {
        promise(.failure(NSError(domain: "GooglePlacesNetworkService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deinitialized"])))
        return
      }
      
      self.placesClient.findAutocompletePredictions(
        fromQuery: query,
        filter: filter,
        sessionToken: nil
      ) { (predictions, error) in
        if let error = error {
          promise(.failure(error))
          return
        }
        
        if let predictions = predictions {
          promise(.success(predictions))
        } else {
          promise(.success([]))
        }
      }
    }.eraseToAnyPublisher()
  }
  
  // GooglePlacesNetworkService의 fetchPlaceDetails 메서드 개선
  func fetchPlaceDetails(placeID: String, fields: GMSPlaceField) -> AnyPublisher<GMSPlace, Error> {
    return Future<GMSPlace, Error> { [weak self] promise in
      guard let self = self else {
        let error = NSError(
          domain: "GooglePlacesNetworkService",
          code: -1,
          userInfo: [NSLocalizedDescriptionKey: "Service deinitialized"]
        )
        promise(.failure(error))
        return
      }
      
      // placeID 검증
      guard !placeID.isEmpty else {
        let error = NSError(
          domain: "GooglePlacesNetworkService",
          code: 400,
          userInfo: [NSLocalizedDescriptionKey: "Place ID는 비어있을 수 없습니다"]
        )
        promise(.failure(error))
        return
      }
      
      Logger.log(message: "NetworkService: 장소 상세정보 요청 - placeID: \(placeID)")
      
      let sessionToken = GMSAutocompleteSessionToken.init()
      
      self.placesClient.fetchPlace(
        fromPlaceID: placeID,
        placeFields: fields,
        sessionToken: sessionToken
      ) { (place, error) in
        if let error = error {
          Logger.log(message: "NetworkService: 장소 정보 요청 실패 - \(error.localizedDescription)")
          promise(.failure(error))
          return
        }
        
        if let place = place {
          Logger.log(message: "NetworkService: 장소 정보 요청 성공 - \(place.name ?? "이름 없음")")
          promise(.success(place))
        } else {
          let error = NSError(
            domain: "GooglePlacesNetworkService",
            code: -2,
            userInfo: [NSLocalizedDescriptionKey: "장소를 찾을 수 없습니다"]
          )
          Logger.log(message: "NetworkService: 장소를 찾을 수 없음")
          promise(.failure(error))
        }
      }
    }.eraseToAnyPublisher()
  }
}
