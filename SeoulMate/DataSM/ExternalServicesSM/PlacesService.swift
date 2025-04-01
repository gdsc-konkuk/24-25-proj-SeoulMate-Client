//
//  PlacesService.swift
//  SeoulMate
//
//  Created by 박성근 on 4/2/25.
//

import Foundation
import GooglePlaces
import Combine

protocol PlacesServiceProtocol {
  func fetchPlacePhotos(placeId: String) -> AnyPublisher<[GMSPlacePhotoMetadata], Error>
  func fetchPhoto(photoMetadata: GMSPlacePhotoMetadata, maxSize: CGSize) -> AnyPublisher<UIImage, Error>
}

final class PlacesService: PlacesServiceProtocol {
  private let placesClient: GMSPlacesClient
  
  init(placesClient: GMSPlacesClient = GMSPlacesClient.shared()) {
    self.placesClient = placesClient
  }
  
  func fetchPlacePhotos(placeId: String) -> AnyPublisher<[GMSPlacePhotoMetadata], Error> {
    return Future<[GMSPlacePhotoMetadata], Error> { [weak self] promise in
      guard let self = self else {
        promise(.failure(NSError(domain: "PlacesService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deinitialized"])))
        return
      }
      
      self.placesClient.lookUpPhotos(forPlaceID: placeId) { photos, error in
        if let error = error {
          promise(.failure(error))
          return
        }
        
        if let results = photos?.results {
          promise(.success(results))
        } else {
          promise(.success([]))
        }
      }
    }.eraseToAnyPublisher()
  }
  
  func fetchPhoto(photoMetadata: GMSPlacePhotoMetadata, maxSize: CGSize) -> AnyPublisher<UIImage, Error> {
    return Future<UIImage, Error> { [weak self] promise in
      guard let self = self else {
        promise(.failure(NSError(domain: "PlacesService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deinitialized"])))
        return
      }
      
      let fetchPhotoRequest = GMSFetchPhotoRequest(photoMetadata: photoMetadata, maxSize: maxSize)
      self.placesClient.fetchPhoto(with: fetchPhotoRequest) { image, error in
        if let error = error {
          promise(.failure(error))
          return
        }
        
        if let image = image {
          promise(.success(image))
        } else {
          promise(.failure(NSError(domain: "PlacesService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch image"])))
        }
      }
    }.eraseToAnyPublisher()
  }
}
