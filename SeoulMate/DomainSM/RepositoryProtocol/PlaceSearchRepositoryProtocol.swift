//
//  PlaceSearchRepositoryProtocol.swift
//  SeoulMate
//
//  Created by 박성근 on 4/3/25.
//

import Foundation
import GooglePlaces
import Combine
import CoreLocation

protocol PlaceSearchRepositoryProtocol {
  func findAutocompletePredictions(query: String, region: CLLocationCoordinate2D?) -> AnyPublisher<[GMSAutocompletePrediction], Error>
  func fetchPlaceDetails(placeID: String) -> AnyPublisher<GMSPlace, Error>
  func fetchPlacePhoto(photoMetadata: GMSPlacePhotoMetadata, maxSize: CGSize) -> AnyPublisher<UIImage, Error>
}
