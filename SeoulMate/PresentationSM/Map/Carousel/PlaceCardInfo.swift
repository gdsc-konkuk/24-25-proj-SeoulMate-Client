//
//  PlaceCardInfo.swift
//  SeoulMate
//
//  Created by 박성근 on 5/4/25.
//

import Foundation
import GoogleMaps
import GooglePlaces

struct PlaceCardInfo {
  let name: String
  let address: String
  let distance: Double // in kilometers
  let rating: Double?
  let reviewCount: Int?
  let imageUrl: String?
  let placeId: String? // Google Place ID
  
  var distanceText: String {
    if distance < 1 {
      return String(format: "%.0fm", distance * 1000)
    } else {
      return String(format: "%.1fkm", distance)
    }
  }
  
  var ratingText: String {
    guard let rating = rating else { return "No rating" }
    if let reviewCount = reviewCount {
      return String(format: "%.1f (%d)", rating, reviewCount)
    } else {
      return String(format: "%.1f", rating)
    }
  }
}

// MARK: - Google Places API 확장
extension PlaceCardInfo {
  // Google Places API 데이터로부터 PlaceCardInfo 생성
  static func from(place: GMSPlace, currentLocation: CLLocationCoordinate2D) -> PlaceCardInfo {
    // 거리 계산
    let placeLocation = CLLocation(
      latitude: place.coordinate.latitude,
      longitude: place.coordinate.longitude
    )
    
    let userLocation = CLLocation(
      latitude: currentLocation.latitude,
      longitude: currentLocation.longitude
    )
    
    let distance = userLocation.distance(from: placeLocation) / 1000 // km로 변환
    
    // 이미지 URL 생성 (Google Places Photo API)
    var imageUrl: String?
    if let photoMetadata = place.photos?.first {
      // 실제 구현시 API key를 사용해서 URL 생성
      imageUrl = "photoURL" // placeholder
    }
    
    return PlaceCardInfo(
      name: place.name ?? "Unknown Place",
      address: place.formattedAddress ?? "No address available",
      distance: distance,
      rating: place.rating > 0 ? Double(place.rating) : nil,
      reviewCount: place.userRatingsTotal > 0 ? Int(place.userRatingsTotal) : nil,
      imageUrl: imageUrl,
      placeId: place.placeID
    )
  }
  
  static func from(placeResponse: PlaceResponse, currentLocation: CLLocationCoordinate2D) -> PlaceCardInfo {
    let coordinate = CLLocationCoordinate2D(
      latitude: placeResponse.coordinate.latitude,
      longitude: placeResponse.coordinate.longitude
    )
    
    // 거리 계산
    let placeLocation = CLLocation(
      latitude: coordinate.latitude,
      longitude: coordinate.longitude
    )
    let userLocation = CLLocation(
      latitude: currentLocation.latitude,
      longitude: currentLocation.longitude
    )
    
    let distance = userLocation.distance(from: placeLocation) / 1000
    
    // TODO: 서버와의 논의를 통해 조정
    return PlaceCardInfo(
      name: placeResponse.address,
      address: placeResponse.address,
      distance: distance,
      rating: nil,
      reviewCount: nil,
      imageUrl: placeResponse.image,
      placeId: placeResponse.id
    )
  }
}
