//
//  PlaceImageDTO.swift
//  SeoulMate
//
//  Created by 박성근 on 4/2/25.
//

import UIKit

struct PlaceImageDTO {
  let image: UIImage
  let attribution: String?
  let authorAttribution: String?
}

extension PlaceImageDTO {
  func toDomain() -> PlaceImage {
    return PlaceImage(
      image: image,
      attribution: attribution,
      authorAttribution: authorAttribution
    )
  }
}
