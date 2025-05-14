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
  let placeID: String?
  let name: String
  let address: String
  let distance: Double
  let rating: Float?
  let ratingCount: Int?
  let description: String?
  
  var distanceText: String {
    if distance < 1000 {
      return String(format: "%.0fm", distance)
    } else {
      return String(format: "%.1fkm", distance / 1000)
    }
  }
  
  var ratingText: String {
    guard let rating = rating else { return "No rating" }
    if let count = ratingCount {
      return String(format: "%.1f (%d)", rating, count)
    }
    return String(format: "%.1f", rating)
  }
  
  static func from(place: GMSPlace, currentLocation: CLLocationCoordinate2D) -> PlaceCardInfo {
    let placeLocation = CLLocation(
      latitude: place.coordinate.latitude,
      longitude: place.coordinate.longitude
    )
    let currentCLLocation = CLLocation(
      latitude: currentLocation.latitude,
      longitude: currentLocation.longitude
    )
    let distance = currentCLLocation.distance(from: placeLocation)
    
    return PlaceCardInfo(
      placeID: place.placeID ?? "",
      name: place.name ?? "Unknown",
      address: place.formattedAddress ?? "No address",
      distance: distance,
      rating: place.rating,
      ratingCount: Int(place.userRatingsTotal),
      description: nil
    )
  }
}
