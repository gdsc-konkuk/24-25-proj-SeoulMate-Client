//
//  UserSessionManager.swift
//  SeoulMate
//
//  Created on 4/8/25.
//

import Foundation
import Combine
import GoogleSignIn

enum UserSessionState {
  case newUser(user: GIDGoogleUser)    // 첫 로그인 사용자
  case existingUser(user: GIDGoogleUser) // 기존 사용자
  case signedOut
  case unknown
}

final class UserSessionManager {
  // 싱글톤 패턴
  static let shared = UserSessionManager()
  
  // 사용자 세션 상태를 방출하는 publisher
  private let userSessionSubject = CurrentValueSubject<UserSessionState, Never>(.unknown)
  var userSessionPublisher: AnyPublisher<UserSessionState, Never> {
    return userSessionSubject.eraseToAnyPublisher()
  }
  
  // 현재 로그인된 사용자
  var currentUser: GIDGoogleUser? {
    switch userSessionSubject.value {
    case .newUser(let user), .existingUser(let user):
      return user
    default:
      return nil
    }
  }
  
  // 현재 로그인 상태
  var isSignedIn: Bool {
    switch userSessionSubject.value {
    case .newUser, .existingUser:
      return true
    default:
      return false
    }
  }
  
  // 첫 로그인 사용자인지 여부
  var isNewUser: Bool {
    if case .newUser = userSessionSubject.value {
      return true
    }
    return false
  }
  
  private init() {
    // 초기 상태 설정 (앱 실행 시 이전 로그인 상태 복원)
    restorePreviousSession()
  }
  
  // 이전 세션 복원
  func restorePreviousSession() {
    if let user = GIDSignIn.sharedInstance.currentUser {
      // 기존 사용자 검증 (UserDefaults 등에서 확인)
      checkUserRegistrationStatus(for: user)
    } else {
      userSessionSubject.send(.signedOut)
    }
  }
  
  // 로그인 처리
  func signIn(user: GIDGoogleUser) {
    // 사용자가 기존에 가입했는지 확인
    checkUserRegistrationStatus(for: user)
  }
  
  // 사용자 가입 상태 확인
  private func checkUserRegistrationStatus(for user: GIDGoogleUser) {
    // 서버 구현 전이므로 모든 사용자를 신규 사용자로 처리
    userSessionSubject.send(.newUser(user: user))
    
    /* 서버 구현 후 활성화할 코드
     // 사용자 이메일 가져오기
     let email = user.profile?.email ?? ""
     
     // API 연동 코드
     // API.checkUserExists(email: email) { [weak self] exists in
     //     if exists {
     //         self?.userSessionSubject.send(.existingUser(user: user))
     //     } else {
     //         self?.userSessionSubject.send(.newUser(user: user))
     //     }
     // }
     */
  }
  
  // 로그아웃 처리
  func signOut() {
    GIDSignIn.sharedInstance.signOut()
    userSessionSubject.send(.signedOut)
  }
  
  // 온보딩 완료 처리 - 신규 사용자를 기존 사용자로 변경
  func completeOnboarding() {
    if case .newUser(let user) = userSessionSubject.value {
      userSessionSubject.send(.existingUser(user: user))
      
      // 나중에 서버 구현 시 활성화
      // API.registerUserPreferences(...) { success in
      //     if success {
      //         self.userSessionSubject.send(.existingUser(user: user))
      //     }
      // }
    }
  }
  
  // Google 로그인 시작
  func startGoogleSignIn(presentingViewController: UIViewController, completion: @escaping (Bool) -> Void) {
    GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { [weak self] signInResult, error in
      if let error = error {
        print("Google 로그인 에러: \(error.localizedDescription)")
        completion(false)
        return
      }
      
      guard let self = self, let user = signInResult?.user else {
        completion(false)
        return
      }
      
      // 로그인 상태 업데이트
      self.signIn(user: user)
      completion(true)
    }
  }
}
