//
//  NetworkProvider.swift
//  SeoulMate
//
//  Created by 박성근 on 5/3/25.
//

// NetworkSM/Core/NetworkProvider.swift
import Foundation
import Alamofire
import Combine

protocol NetworkProviderProtocol {
  func request<T: Decodable>(_ endpoint: Endpoint) -> AnyPublisher<T, NetworkError>
}

final class EmptyResponseSerializer: ResponseSerializer {
  func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> EmptyResponse {
    if let error = error {
      throw error
    }
    return EmptyResponse()
  }
}

final class NetworkProvider: NetworkProviderProtocol {
  private let session: Session
  private var cancellables: Set<AnyCancellable> = []
  
  init(interceptor: RequestInterceptor? = NetworkInterceptor(),
       eventMonitors: [EventMonitor] = [NetworkLogger()]) {
    let configuration = URLSessionConfiguration.default
    configuration.timeoutIntervalForRequest = 120
    configuration.timeoutIntervalForResource = 180
    configuration.headers = .default
    
    self.session = Session(
      configuration: configuration,
      interceptor: interceptor,
      eventMonitors: eventMonitors
    )
  }
  
  func request<T: Decodable>(_ endpoint: Endpoint) -> AnyPublisher<T, NetworkError> {
    return Future<T, NetworkError> { promise in
      do {
        let urlRequest = try endpoint.asURLRequest()
        Logger.log("🔍 Created URLRequest: \(urlRequest.httpMethod ?? "unknown") \(urlRequest.url?.absoluteString ?? "")")
        Logger.log("🔍 Request Headers: \(urlRequest.allHTTPHeaderFields ?? [:])")
        Logger.log("🔍 Request Body: \(String(data: urlRequest.httpBody ?? Data(), encoding: .utf8) ?? "none")")
        
        self.session.request(urlRequest)
          .validate()
          .response(responseSerializer: EmptyResponseSerializer()) { response in
            switch response.result {
            case .success(let value):
              if T.self == EmptyResponse.self {
                promise(.success(value as! T))
              } else {
                // EmptyResponse가 아닌 경우 일반 디코딩 시도
                self.session.request(urlRequest)
                  .validate()
                  .responseDecodable(of: T.self) { response in
                    switch response.result {
                    case .success(let value):
                      promise(.success(value))
                    case .failure(let error):
                      if let response = response.response {
                        promise(.failure(self.handleError(error, response: response)))
                      } else {
                        promise(.failure(.unknown(error)))
              }
                    }
                  }
              }
            case .failure(let error):
              if let response = response.response {
                promise(.failure(self.handleError(error, response: response)))
              } else {
                promise(.failure(.unknown(error)))
              }
            }
          }
      } catch {
        promise(.failure(.invalidURL))
      }
    }
    .eraseToAnyPublisher()
  }
  
  private func handleError(_ error: Error, response: HTTPURLResponse?) -> NetworkError {
    guard let statusCode = response?.statusCode else {
      return .unknown(error)
    }
    
    switch statusCode {
    case 401:
      return .unauthorized
    case 400...499:
      return .serverError(statusCode: statusCode)
    case 500...599:
      return .serverError(statusCode: statusCode)
    default:
      return .unknown(error)
    }
  }
}
