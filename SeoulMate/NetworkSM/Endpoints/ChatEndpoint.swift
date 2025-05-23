//
//  ChatEndpoint.swift
//  SeoulMate
//
//  Created by 박성근 on 5/12/25.
//

import Foundation
import Alamofire

enum ChatEndpoint: Endpoint {
  case sendMessage(placeId: String?, chatType: ChatType, text: String)
  
  var path: String {
    switch self {
    case .sendMessage(let placeId, _, _):
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
    case .sendMessage(_, _, let text):
      return [
        "history": [
          [
            "role": "human",
            "content": text
          ]
        ],
        "input": text
      ]
    }
  }
  
  var queryParameters: Parameters? {
    switch self {
    case .sendMessage(_, let chatType, _):
      return ["chatType": chatType.rawValue]
    }
  }
  
  var encoding: ParameterEncoding {
    return JSONEncoding.default
  }
}
