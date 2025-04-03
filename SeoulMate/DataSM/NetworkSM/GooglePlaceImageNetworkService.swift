//
//  PlaceImageNetworkService.swift
//  SeoulMate
//
//  Created by 박성근 on 4/2/25.
//

import Foundation
import Combine
import GooglePlaces
import UIKit

protocol GooglePlaceImageNetworkServiceProtocol {
  func fetchPlaceImages(placeId: String, maxSize: CGSize) -> AnyPublisher<[PlaceImageDTO], Error>
  func fetchPlaceFirstImage(placeId: String, maxSize: CGSize) -> AnyPublisher<PlaceImageDTO?, Error>
}

final class GooglePlaceImageNetworkService: GooglePlaceImageNetworkServiceProtocol {
  private let networkService: NetworkServiceProtocol
  private let placesService: PlacesServiceProtocol
  
  init(networkService: NetworkServiceProtocol, placesService: PlacesServiceProtocol) {
    self.networkService = networkService
    self.placesService = placesService
  }
  
  func fetchPlaceImages(placeId: String, maxSize: CGSize) -> AnyPublisher<[PlaceImageDTO], Error> {
    return placesService.fetchPlacePhotos(placeId: placeId)
      .flatMap { photoMetadataList -> AnyPublisher<[PlaceImageDTO], Error> in
        let imagePublishers = photoMetadataList.map { metadata in
          return self.placesService.fetchPhoto(photoMetadata: metadata, maxSize: maxSize)
            .map { image in
              PlaceImageDTO(
                image: image,
                attribution: metadata.attributions?.string,
                authorAttribution: metadata.attributions?.string
              )
            }
        }
        
        // 각 이미지 가져오기가 끝나면 결과 배열 반환
        return Publishers.MergeMany(imagePublishers)
          .collect()
          .eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }
  
  func fetchPlaceFirstImage(placeId: String, maxSize: CGSize) -> AnyPublisher<PlaceImageDTO?, Error> {
    return placesService.fetchPlacePhotos(placeId: placeId)
      .flatMap { photoMetadataList -> AnyPublisher<PlaceImageDTO?, Error> in
        guard let firstMetadata = photoMetadataList.first else {
          return Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
        
        return self.placesService.fetchPhoto(photoMetadata: firstMetadata, maxSize: maxSize)
          .map { image in
            PlaceImageDTO(
              image: image,
              attribution: firstMetadata.attributions?.string,
              authorAttribution: firstMetadata.attributions?.string
            )
          }
          .map { $0 as PlaceImageDTO? }
          .eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }
}
