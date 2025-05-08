//
//  NetworkInterceptor.swift
//  SeoulMate
//
//  Created by 박성근 on 5/3/25.
//

import Foundation
import Alamofire
import Combine

final class NetworkInterceptor: RequestInterceptor {
  
  private let keychain = KeychainManager.shared
  private let service = "com.seoulmate.auth"
  private let tokenAccount = "accessToken"
  
  // 토큰 재발급 시도 횟수 제한
  private var retryLimit = 3
  private var retryCount = 0
  
  // MARK: - Request Adapter
  func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
    var urlRequest = urlRequest
    
    // 토큰이 필요 없는 엔드포인트 체크
    if isPublicEndpoint(urlRequest) {
      completion(.success(urlRequest))
      return
    }
    
    // 키체인에서 토큰 가져오기
    do {
      let tokenData = try keychain.read(service: service, account: tokenAccount)
      if let accessToken = String(data: tokenData, encoding: .utf8) {
        urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
      }
      completion(.success(urlRequest))
    } catch {
      // 토큰이 없어도 요청은 진행
      completion(.success(urlRequest))
    }
  }
  
  // MARK: - Request Retrier
  func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
    guard let response = request.task?.response as? HTTPURLResponse,
          response.statusCode == 401 else {
      return completion(.doNotRetry)
    }
    
    // 재시도 횟수 체크
    guard retryCount < retryLimit else {
      retryCount = 0
      // 토큰 갱신 실패 시 로그인 화면으로 이동
      NotificationCenter.default.post(name: .userSessionExpired, object: nil)
      return completion(.doNotRetry)
    }
    
    retryCount += 1
    
    // 토큰 갱신 로직
    refreshToken { [weak self] success in
      guard let self = self else { return }
      
      if success {
        self.retryCount = 0
        completion(.retry)
      } else {
        completion(.doNotRetry)
      }
    }
  }
  
  // MARK: - Private Methods
  private func isPublicEndpoint(_ urlRequest: URLRequest) -> Bool {
    guard let url = urlRequest.url?.absoluteString else { return false }
    
    // 인증이 필요 없는 엔드포인트 목록
    let publicEndpoints = [
      "/auth/login",
      "/auth/refresh"
    ]
    
    return publicEndpoints.contains { url.contains($0) }
  }
  
  private func refreshToken(completion: @escaping (Bool) -> Void) {
    do {
      let refreshTokenData = try keychain.read(service: service, account: "refreshToken")
      let accessTokenData = try keychain.read(service: service, account: tokenAccount)
      
      guard let refreshToken = String(data: refreshTokenData, encoding: .utf8),
            let accessToken = String(data: accessTokenData, encoding: .utf8) else {
        completion(false)
        return
      }
      
      let authService = AuthService(networkProvider: NetworkProvider())
      let cancellable = authService.refreshToken(refreshToken: refreshToken, accessToken: accessToken)
        .sink(
          receiveCompletion: { result in
            switch result {
            case .finished:
              break
            case .failure:
              completion(false)
            }
          },
          receiveValue: { response in
            // 새로운 토큰 저장
            do {
              try self.keychain.save(
                response.accessToken.data(using: .utf8) ?? Data(),
                service: self.service,
                account: self.tokenAccount
              )
              try self.keychain.save(
                response.refreshToken.data(using: .utf8) ?? Data(),
                service: self.service,
                account: "refreshToken"
              )
              completion(true)
            } catch {
              completion(false)
            }
          }
        )
      
      // 메모리 누수 방지를 위해 cancellable 저장
      _ = cancellable
    } catch {
      completion(false)
    }
  }
}

// MARK: - Notification Name Extension
extension Notification.Name {
  static let userSessionExpired = Notification.Name("userSessionExpired")
}
