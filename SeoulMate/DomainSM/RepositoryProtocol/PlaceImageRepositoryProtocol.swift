//
//  PlaceImageRepositoryProtocol.swift
//  SeoulMate
//
//  Created by 박성근 on 4/1/25.
//

import Foundation
import Combine

protocol PlaceImageRepositoryProtocol {
  func fetchPlaceImages(placeId: String, maxSize: CGSize) -> AnyPublisher<[PlaceImage], Error>
  func fetchPlaceFirstImage(placeId: String, maxSize: CGSize) -> AnyPublisher<PlaceImage?, Error>
}
