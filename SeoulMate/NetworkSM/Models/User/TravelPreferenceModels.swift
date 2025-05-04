//
//  TravelPreferenceModels.swift
//  SeoulMate
//
//  Created by 박성근 on 5/3/25.
//

import Foundation

enum TravelCompanion: String, Codable {
  case alone = "Alone"
  case friends = "Friends"
  case parents = "Parents"
  case lover = "Lover"
  case spouse = "Spouse"
  case children = "Children"
  case etc = "etc."
}

enum TravelPurpose: String, Codable {
  case activities = "Activities"
  case nature = "Nature"
  case shopping = "Shopping"
  case snsHotPlaces = "SNS hot places"
  case cultureArtHistory = "Culture-Art-History"
  case eating = "Eating"
  case touristSpot = "Tourist spot"
}
