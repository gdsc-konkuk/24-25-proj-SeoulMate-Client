//
//  GoogleAuthService.swift
//  SeoulMate
//
//  Created by 박성근 on 3/31/25.
//

import Foundation
import GoogleSignIn
import Combine

protocol GoogleAuthServiceProtocol {
  func signIn(presentingViewController: UIViewController) -> AnyPublisher<(idToken: String, accessToken: String), Error>
  func signOut() -> AnyPublisher<Void, Error>
}

final class GoogleAuthService: GoogleAuthServiceProtocol {
  
  func signIn(presentingViewController: UIViewController) -> AnyPublisher<(idToken: String, accessToken: String), Error> {
    return Future<(idToken: String, accessToken: String), Error> { promise in
      GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
        if let error = error {
          promise(.failure(error))
          return
        }
        
        guard let user = result?.user,
              let idToken = user.idToken?.tokenString else {
          promise(.failure(NSError(domain: "GoogleAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Google ID Token을 가져오는데 실패했습니다."])))
          return
        }
        
        let accessToken = user.accessToken.tokenString
        
        promise(.success((idToken: idToken, accessToken: accessToken)))
      }
    }.eraseToAnyPublisher()
  }
  
  func signOut() -> AnyPublisher<Void, Error> {
    return Future<Void, Error> { promise in
      GIDSignIn.sharedInstance.signOut()
      promise(.success(()))
    }.eraseToAnyPublisher()
  }
}
