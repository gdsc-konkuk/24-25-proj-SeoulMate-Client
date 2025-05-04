//
//  NetworkLogger.swift
//  SeoulMate
//
//  Created by 박성근 on 5/3/25.
//

import Foundation
import Alamofire

final class NetworkLogger: EventMonitor {
  
  func requestDidResume(_ request: Request) {
    let body = request.request.flatMap { $0.httpBody.map { String(decoding: $0, as: UTF8.self) } } ?? "None"
    let message = """
        
        🚀 ============================ REQUEST ============================
        🔸 URL: \(request.request?.url?.absoluteString ?? "")
        🔸 Method: \(request.request?.httpMethod ?? "")
        🔸 Headers: \(request.request?.allHTTPHeaderFields ?? [:])
        🔸 Body: \(body)
        ================================================================
        """
    print(message)
  }
  
  func request<Value>(_ request: DataRequest, didParseResponse response: DataResponse<Value, AFError>) {
    switch response.result {
    case .success(let value):
      let message = """
            
            ✅ ============================ RESPONSE ============================
            🔹 URL: \(request.request?.url?.absoluteString ?? "")
            🔹 Status Code: \(response.response?.statusCode ?? 0)
            🔹 Data: \(value)
            ================================================================
            """
      print(message)
      
    case .failure(let error):
      let message = """
            
            ❌ ============================ ERROR ==============================
            🔹 URL: \(request.request?.url?.absoluteString ?? "")
            🔹 Status Code: \(response.response?.statusCode ?? 0)
            🔹 Error: \(error.localizedDescription)
            ================================================================
            """
      print(message)
    }
  }
}

// MARK: - Custom Network Logger
final class CustomNetworkLogger {
  static let shared = CustomNetworkLogger()
  
  private init() {}
  
  func log(request: URLRequest?) {
#if DEBUG
    guard let request = request else { return }
    
    let urlString = request.url?.absoluteString ?? "No URL"
    let method = request.httpMethod ?? "No Method"
    let headers = request.allHTTPHeaderFields ?? [:]
    let body = request.httpBody.flatMap { String(data: $0, encoding: .utf8) } ?? "No Body"
    
    print("""
        
        📡 Network Request:
        - URL: \(urlString)
        - Method: \(method)
        - Headers: \(headers)
        - Body: \(body)
        
        """)
#endif
  }
  
  func log(response: HTTPURLResponse?, data: Data?, error: Error?) {
#if DEBUG
    let statusCode = response?.statusCode ?? 0
    let dataString = data.flatMap { String(data: $0, encoding: .utf8) } ?? "No Data"
    let errorString = error?.localizedDescription ?? "No Error"
    
    print("""
        
        📡 Network Response:
        - Status Code: \(statusCode)
        - Data: \(dataString)
        - Error: \(errorString)
        
        """)
#endif
  }
}
