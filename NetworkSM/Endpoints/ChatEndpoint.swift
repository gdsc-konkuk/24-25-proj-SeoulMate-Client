//
//  ChatEndpoint.swift
//  SeoulMate
//
//  Created by 박성근 on 5/12/25.
//

import Foundation
import Alamofire

enum ChatEndpoint: Endpoint {
  case sendMessage(placeId: String?, chatType: ChatType)
  
  var path: String {
    switch self {
    case .sendMessage(let placeId, _):
      if let placeId = placeId, !placeId.isEmpty {
        return "/places/chat/\(placeId)"
      } else {
        return "/places/chat"
      }
    }
  }
  
  var method: HTTPMethod { .post }
  
  var parameters: Parameters? {
    switch self {
    case .sendMessage(_, let chatType):
      return ["chatType": chatType.rawValue]
    }
  }
  
  var encoding: ParameterEncoding {
    return URLEncoding(destination: .queryString)
  }
} 