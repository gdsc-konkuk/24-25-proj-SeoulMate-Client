//
//  LoginUseCaseProtocol.swift
//  SeoulMate
//
//  Created by 박성근 on 5/4/25.
//

import Foundation
import Combine

protocol LoginUseCaseProtocol {
  func execute(idToken: String) -> AnyPublisher<LoginResponse, NetworkError>
}
