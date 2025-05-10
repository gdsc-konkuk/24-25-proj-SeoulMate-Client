//
//  NetworkLogger.swift
//  SeoulMate
//
//  Created by 박성근 on 5/3/25.
//

import Foundation
import Alamofire
import os.log

final class NetworkLogger: EventMonitor {
  
  // 요청이 생성될 때
  func requestDidCreate(_ request: Request) {
    os_log("Request Created", log: .default, type: .debug)
  }
  
  // 요청이 시작될 때
  func requestDidResume(_ request: Request) {
    os_log("Request Resumed", log: .default, type: .debug)
    
    guard let urlRequest = request.request else {
      os_log("URLRequest is nil", log: .default, type: .error)
      return
    }
    
    let body = urlRequest.httpBody.flatMap { String(decoding: $0, as: UTF8.self) } ?? "None"
    let parameters = urlRequest.httpMethod == "GET" ? 
      urlRequest.url?.query ?? "None" :
      body
    
    let message = """
        
        🚀 ============================ REQUEST ============================
        🔸 URL: \(urlRequest.url?.absoluteString ?? "")
        🔸 Method: \(urlRequest.httpMethod ?? "")
        🔸 Headers: \(urlRequest.allHTTPHeaderFields ?? [:])
        🔸 Parameters: \(parameters)
        🔸 Request ID: \(request.id)
        🔸 Original Request: \(urlRequest)
        ================================================================
        """
    os_log("%{public}@", log: .default, type: .debug, message)
  }
  
  // 요청이 일시 중지될 때
  func requestDidSuspend(_ request: Request) {
    os_log("Request Suspended", log: .default, type: .debug)
  }
  
  // 요청이 취소될 때
  func requestDidCancel(_ request: Request) {
    os_log("Request Cancelled", log: .default, type: .debug)
  }
  
  // 요청이 완료될 때
  func requestDidFinish(_ request: Request) {
    os_log("Request Finished", log: .default, type: .debug)
  }
  
  // 응답을 받았을 때
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
      os_log("%{public}@", log: .default, type: .debug, message)
      
    case .failure(let error):
      let message = """
            
            ❌ ============================ ERROR ==============================
            🔹 URL: \(request.request?.url?.absoluteString ?? "")
            🔹 Status Code: \(response.response?.statusCode ?? 0)
            🔹 Error: \(error.localizedDescription)
            ================================================================
            """
      os_log("%{public}@", log: .default, type: .error, message)
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
