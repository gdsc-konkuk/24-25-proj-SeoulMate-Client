//
//  GooglePlacesRepository.swift
//  SeoulMate
//
//  Created by 박성근 on 4/3/25.
//

import Foundation
import GooglePlaces
import Combine
import CoreLocation
import UIKit

protocol PlacesRepositoryProtocol {
  // 자동완성 검색
  func findAutocompletePredictions(query: String, region: CLLocationCoordinate2D?) -> AnyPublisher<[GMSAutocompletePrediction], Error>
  
  // 장소 세부 정보 가져오기
  func fetchPlaceDetails(placeID: String) -> AnyPublisher<GMSPlace, Error>
  
  // PlaceInfo 모델로 변환하기
  func getPlaceInfo(from place: GMSPlace, userLocation: CLLocation?) -> AnyPublisher<PlaceInfo, Error>
  
  // 장소 이미지 가져오기 (여러 개)
  func fetchPlaceImages(placeId: String, maxSize: CGSize) -> AnyPublisher<[PlaceImage], Error>
  
  // 장소 이미지 가져오기 (첫 번째 이미지)
  func fetchPlaceFirstImage(placeId: String, maxSize: CGSize) -> AnyPublisher<PlaceImage?, Error>
}

final class PlacesRepository: PlacesRepositoryProtocol {
  private let networkService: GooglePlacesNetworkServiceProtocol
  private let imageNetworkService: GooglePlaceImageNetworkServiceProtocol
  
  init(networkService: GooglePlacesNetworkServiceProtocol, imageNetworkService: GooglePlaceImageNetworkServiceProtocol) {
    self.networkService = networkService
    self.imageNetworkService = imageNetworkService
  }
  
  func findAutocompletePredictions(query: String, region: CLLocationCoordinate2D? = nil) -> AnyPublisher<[GMSAutocompletePrediction], Error> {
    let filter = GMSAutocompleteFilter()
    filter.countries = ["KR"] // 한국으로 제한
    
    return networkService.findAutocompletePredictions(query: query, filter: filter)
  }
  
  func fetchPlaceDetails(placeID: String) -> AnyPublisher<GMSPlace, Error> {
    // placeID 검증
    guard !placeID.isEmpty else {
      return Fail(error: NSError(
        domain: "PlacesRepository",
        code: 400,
        userInfo: [NSLocalizedDescriptionKey: "Place ID는 비어있을 수 없습니다"]
      )).eraseToAnyPublisher()
    }
    
    // 필요한 모든 필드 명시적으로 요청 - 중요: photos 필드를 포함해야 함
    let fields: GMSPlaceField = [
      .name,
      .formattedAddress,
      .coordinate,
      .photos,          // photos 필드 명시
      .placeID,
      .types,
      .website,         // 추가 정보
      .phoneNumber,     // 추가 정보
      .rating,          // 추가 정보
      .priceLevel       // 추가 정보
    ]
    
    Logger.log(message: "Repository: Places API 호출 - placeID: \(placeID)")
    
    return networkService.fetchPlaceDetails(placeID: placeID, fields: fields)
      .handleEvents(receiveSubscription: { _ in
        Logger.log(message: "Repository: Places API 구독 시작")
      }, receiveOutput: { place in
        // 사진 메타데이터 로깅 추가
        if let photos = place.photos {
          Logger.log(message: "Repository: 장소 사진 개수: \(photos.count)개")
        } else {
          Logger.log(message: "Repository: 장소 사진 정보 없음")
        }
        Logger.log(message: "Repository: Places API 응답 성공 - \(place.name ?? "이름 없음")")
      }, receiveCompletion: { completion in
        switch completion {
        case .finished:
          Logger.log(message: "Repository: Places API 호출 완료")
        case .failure(let error):
          Logger.log(message: "Repository: Places API 호출 실패 - \(error.localizedDescription)")
        }
      })
      .eraseToAnyPublisher()
  }
  
  // getPlaceInfo 메서드 개선
  func getPlaceInfo(from place: GMSPlace, userLocation: CLLocation? = nil) -> AnyPublisher<PlaceInfo, Error> {
    // 필수 데이터 확인
    guard let placeID = place.placeID else {
      return Fail(error: NSError(
        domain: "PlacesRepository",
        code: 400,
        userInfo: [NSLocalizedDescriptionKey: "장소 ID가 없습니다"]
      )).eraseToAnyPublisher()
    }
    
    Logger.log(message: "Repository: PlaceInfo 생성 시작 - \(place.name ?? "이름 없음")")
    
    // 기본 PlaceInfo 생성
    var placeInfo = PlaceInfo(
      id: placeID,
      name: place.name ?? "알 수 없는 장소",
      address: place.formattedAddress ?? "",
      imageURL: nil,
      distance: 0.0,
      coordinate: (place.coordinate.latitude, place.coordinate.longitude),
      placeId: placeID
    )
    
    // 거리 계산
    if let userLocation = userLocation {
      let placeLocation = CLLocation(
        latitude: place.coordinate.latitude,
        longitude: place.coordinate.longitude
      )
      placeInfo.distance = userLocation.distance(from: placeLocation) / 1000.0 // km 단위
    }
    
    // 이미지가 없는 경우 바로 완료
    guard let _ = place.photos?.first else {
      Logger.log(message: "Repository: 장소 이미지 없음, PlaceInfo 생성 완료")
      return Just(placeInfo)
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    }
    
    // 첫 번째 이미지 가져오기
    return fetchPlaceFirstImage(placeId: placeID, maxSize: CGSize(width: 300, height: 300))
      .handleEvents(receiveCompletion: { completion in
        if case .failure(let error) = completion {
          Logger.log(message: "Repository: 이미지 로드 실패 - \(error.localizedDescription)")
        }
      })
      .map { placeImage -> PlaceInfo in
        // 이미지를 가져오는데 성공했다면 URL 설정
        if let _ = placeImage {
          Logger.log(message: "Repository: 이미지 로드 성공")
          // imageURL은 나중에 적절히 활용할 수 있도록 ID 형태로 저장
          placeInfo.imageURL = "place_\(placeID)"
        }
        return placeInfo
      }
      .catch { error -> AnyPublisher<PlaceInfo, Error> in
        // 이미지 로드 실패 시에도 기본 PlaceInfo는 반환
        Logger.log(message: "Repository: 이미지 로드 중 오류 발생했으나 기본 PlaceInfo 반환 - \(error.localizedDescription)")
        return Just(placeInfo)
          .setFailureType(to: Error.self)
          .eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }
  
  func fetchPlaceImages(placeId: String, maxSize: CGSize) -> AnyPublisher<[PlaceImage], Error> {
    return imageNetworkService.fetchPlaceImages(placeId: placeId, maxSize: maxSize)
      .map { dtos in
        return dtos.map { $0.toDomain() }
      }
      .eraseToAnyPublisher()
  }
  
  func fetchPlaceFirstImage(placeId: String, maxSize: CGSize) -> AnyPublisher<PlaceImage?, Error> {
    return imageNetworkService.fetchPlaceFirstImage(placeId: placeId, maxSize: maxSize)
      .map { dto in
        return dto?.toDomain()
      }
      .eraseToAnyPublisher()
  }
}
