//
//  SceneDelegate.swift
//  SeoulMate
//
//  Created by 박성근 on 3/27/25.
//

import UIKit
import GoogleSignIn
import Combine

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  
  var window: UIWindow?
  private var subscriptions = Set<AnyCancellable>()
  
  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else { return }
    self.window = UIWindow(windowScene: windowScene)
    
    // 로그인 상태에 따라 초기 화면 설정
    setupUserSessionSubscription()
    
    self.window?.makeKeyAndVisible()
  }
  
  // Combine을 사용하여 로그인 상태 감시
  private func setupUserSessionSubscription() {
    UserSessionManager.shared.userSessionPublisher
      .receive(on: RunLoop.main)
      .sink { [weak self] state in
        guard let self = self else { return }
        
        switch state {
        case .newUser(let user):
          print("🔵 로그인: 신규 사용자 감지 - \(user.profile?.email ?? "알 수 없음")")
          // 신규 사용자는 TravelWithViewController로 이동
          self.showOnboardingFlow()
        case .existingUser(let user):
          print("🟢 로그인: 기존 사용자 감지 - \(user.profile?.email ?? "알 수 없음")")
          // 기존 사용자는 메인 탭바 컨트롤러로 이동
          self.showMainApp()
        case .signedOut:
          print("🔴 로그아웃: 로그인 화면으로 이동")
          self.showLoginScreen()
        case .unknown:
          print("⚪️ 초기 상태: 로그인 화면으로 이동")
          self.showLoginScreen()
        }
      }
      .store(in: &subscriptions)
  }
  
  // 로그인 화면 표시
  private func showLoginScreen() {
    let socialLoginVC = SocialLoginViewController()
    let navigationController = UINavigationController(rootViewController: socialLoginVC)
    navigationController.setNavigationBarHidden(true, animated: false)
    
    UIView.transition(with: window!,
                      duration: 0.3,
                      options: .transitionCrossDissolve,
                      animations: {
      self.window?.rootViewController = navigationController
    })
  }
  
  // 신규 사용자용 온보딩 플로우 표시
  private func showOnboardingFlow() {
    let travelWithVC = TravelWithViewController()
    let navigationController = UINavigationController(rootViewController: travelWithVC)
    navigationController.setNavigationBarHidden(true, animated: false)
    
    UIView.transition(with: window!,
                      duration: 0.3,
                      options: .transitionCrossDissolve,
                      animations: {
      self.window?.rootViewController = navigationController
    })
  }
  
  // 메인 앱 화면 표시 (탭바 컨트롤러)
  private func showMainApp() {
    let tabBarController = TabBarController()
    
    UIView.transition(with: window!,
                      duration: 0.3,
                      options: .transitionCrossDissolve,
                      animations: {
      self.window?.rootViewController = tabBarController
    })
  }
  
  func sceneDidDisconnect(_ scene: UIScene) {
    // 리소스 정리
    subscriptions.removeAll()
  }
  
  func sceneDidBecomeActive(_ scene: UIScene) {}
  
  func sceneWillResignActive(_ scene: UIScene) {}
  
  func sceneWillEnterForeground(_ scene: UIScene) {}
  
  func sceneDidEnterBackground(_ scene: UIScene) {}
}
