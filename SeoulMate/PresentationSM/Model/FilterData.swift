//
//  FilterData.swift
//  SeoulMate
//
//  Created by 박성근 on 5/3/25.
//

import Foundation

// MARK: - FilterData
struct FilterData: Encodable {
  let companion: String?
  let purposes: [String]
  var userId: Int64?
  
  init(companion: String?, purposes: [String], userId: Int64? = nil) {
    self.companion = companion
    self.purposes = purposes
    self.userId = userId
  }
}
