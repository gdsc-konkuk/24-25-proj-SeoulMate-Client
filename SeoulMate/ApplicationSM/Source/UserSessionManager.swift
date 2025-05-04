//
//  UserSessionManager.swift
//  SeoulMate
//
//  Created on 4/8/25.
//

import Foundation
import GoogleSignIn
import UIKit
import Combine

final class UserSessionManager {
  static let shared = UserSessionManager()
  
  private let keychain = KeychainManager.shared
  private let keychainService = "com.seoulmate.auth"
  private let accessTokenKey = "accessToken"
  private let refreshTokenKey = "refreshToken"
  private let userIdKey = "userId"
  
  private var cancellables = Set<AnyCancellable>()
  
  weak var appDIContainer: AppDIContainer?
  
  private init() {}
  
  // MARK: - Properties
  var isLoggedIn: Bool {
    return getAccessToken() != nil && getCurrentUserId() != nil
  }
  
  var isOnboardingCompleted: Bool {
    get {
      return UserDefaults.standard.bool(forKey: "OnboardingCompleted")
    }
    set {
      UserDefaults.standard.set(newValue, forKey: "OnboardingCompleted")
    }
  }
  
  /// 로그아웃
  func logout() {
    // Google 로그아웃
    GIDSignIn.sharedInstance.signOut()
    
    // 토큰 삭제
    clearAllTokens()
    
    // 사용자 ID 삭제
    UserDefaults.standard.removeObject(forKey: userIdKey)
    UserDefaults.standard.synchronize()
    
    // 기타 사용자 데이터 초기화
    isOnboardingCompleted = false
    
    // 로그인 화면으로 이동
    navigateToLogin()
  }
  
  /// 온보딩 완료
  func completeOnboarding() {
    isOnboardingCompleted = true
  }
  
  // MARK: - Token Management
  func saveTokens(access: String, refresh: String) {
    do {
      let accessData = access.data(using: .utf8)!
      let refreshData = refresh.data(using: .utf8)!
      
      try keychain.save(accessData, service: keychainService, account: accessTokenKey)
      try keychain.save(refreshData, service: keychainService, account: refreshTokenKey)
    } catch {
      print("Failed to save tokens: \(error)")
    }
  }
  
  func getAccessToken() -> String? {
    do {
      let data = try keychain.read(service: keychainService, account: accessTokenKey)
      return String(data: data, encoding: .utf8)
    } catch {
      return nil
    }
  }
  
  func getRefreshToken() -> String? {
    do {
      let data = try keychain.read(service: keychainService, account: refreshTokenKey)
      return String(data: data, encoding: .utf8)
    } catch {
      return nil
    }
  }
  
  func clearAllTokens() {
    do {
      try keychain.delete(service: keychainService, account: accessTokenKey)
      try keychain.delete(service: keychainService, account: refreshTokenKey)
    } catch {
      print("Failed to clear tokens: \(error)")
    }
  }
  
  // MARK: - User ID Management
  func saveUserId(_ userId: Int64) {
    UserDefaults.standard.set(userId, forKey: userIdKey)
    UserDefaults.standard.synchronize()
  }
  
  func getCurrentUserId() -> Int64? {
    guard UserDefaults.standard.object(forKey: userIdKey) != nil else { return nil }
    return Int64(UserDefaults.standard.integer(forKey: userIdKey))
  }
  
  // MARK: - Navigation Methods
  func navigateToLogin() {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = windowScene.windows.first,
          let appDIContainer = self.appDIContainer else { return }
    
    let loginSceneDIContainer = appDIContainer.makeLoginSceneDIContainer()
    let loginViewController = loginSceneDIContainer.makeSocialLoginViewController()
    let navigationController = UINavigationController(rootViewController: loginViewController)
    
    window.rootViewController = navigationController
    window.makeKeyAndVisible()
  }
  
  func navigateToOnboarding() {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = windowScene.windows.first,
          let appDIContainer = self.appDIContainer else { return }
    
    let loginSceneDIContainer = appDIContainer.makeLoginSceneDIContainer()
    let travelWithVC = loginSceneDIContainer.makeTravelWithViewController()
    let navigationController = UINavigationController(rootViewController: travelWithVC)
    
    window.rootViewController = navigationController
    window.makeKeyAndVisible()
  }
  
  func navigateToMain() {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = windowScene.windows.first,
          let appDIContainer = self.appDIContainer else { return }
    
    let tabBarController = appDIContainer.makeTabBarController()
    window.rootViewController = tabBarController
    window.makeKeyAndVisible()
  }
  
  func completeOnboardingAndNavigateToMain() {
    // 온보딩 완료 처리
    isOnboardingCompleted = true
    
    // 메인 화면으로 이동
    navigateToMain()
  }
}
