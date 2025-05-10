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

final class NetworkProvider: NetworkProviderProtocol {
  private let session: Session
  private var cancellables: Set<AnyCancellable> = []
  
  init(interceptor: RequestInterceptor? = NetworkInterceptor(),
       eventMonitors: [EventMonitor] = [NetworkLogger()]) {
    let configuration = URLSessionConfiguration.default
    configuration.timeoutIntervalForRequest = 30
    configuration.timeoutIntervalForResource = 60
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
        print("🔍 Created URLRequest: \(urlRequest.httpMethod ?? "unknown") \(urlRequest.url?.absoluteString ?? "")")
        print("🔍 Request Headers: \(urlRequest.allHTTPHeaderFields ?? [:])")
        print("🔍 Request Body: \(String(data: urlRequest.httpBody ?? Data(), encoding: .utf8) ?? "none")")
        
        self.session.request(urlRequest)
          .validate()
          .publishDecodable(type: T.self)
          .tryMap { response in
            if let error = response.error {
              throw self.handleError(error, response: response.response)
            }
            
            guard let value = response.value else {
              throw NetworkError.invalidData
            }
            
            return value
          }
          .mapError { error in
            if let networkError = error as? NetworkError {
              return networkError
            }
            return NetworkError.unknown(error)
          }
          .sink(
            receiveCompletion: { completion in
              if case .failure(let error) = completion {
                promise(.failure(error))
              }
            },
            receiveValue: { value in
              promise(.success(value))
            }
          )
          .store(in: &self.cancellables)
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
