//
//  SceneDelegate.swift
//  SeoulMate
//
//  Created by 박성근 on 3/27/25.
//

import UIKit
import GoogleSignIn

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  
  var window: UIWindow?
  
  
  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else {return}
    self.window = UIWindow(windowScene: windowScene)
    
    // 로그인 상태에 따라 초기 화면 설정
    configureInitialViewController()
    
    self.window?.makeKeyAndVisible()
    
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(userDidSignIn),
      name: Notification.Name.userDidSignIn,
      object: nil
    )
    
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(userDidSignOut),
      name: Notification.Name.userDidSignOut,
      object: nil
    )
  }
  
  // 로그인 상태에 따른 초기 화면 설정
  private func configureInitialViewController() {
    if let _ = GIDSignIn.sharedInstance.currentUser {
      // 로그인된 상태: TabBarController 표시
      window?.rootViewController = TabBarController()
    } else {
      // 로그인되지 않은 상태: 로그인 화면 표시
      window?.rootViewController = SocialLoginViewController()
    }
  }
  
  // 로그인 성공 시 호출될 메서드
  @objc private func userDidSignIn() {
    // TabBarController로 전환
    UIView.transition(with: window!,
                      duration: 0.3,
                      options: .transitionCrossDissolve,
                      animations: {
      self.window?.rootViewController = TabBarController()
    })
  }
  
  // 로그아웃 시 호출될 메서드
  @objc private func userDidSignOut() {
    // 로그인 화면으로 전환
    UIView.transition(with: window!,
                      duration: 0.3,
                      options: .transitionCrossDissolve,
                      animations: {
      self.window?.rootViewController = SocialLoginViewController()
    })
  }
  
  func sceneDidDisconnect(_ scene: UIScene) {
    
  }
  
  func sceneDidBecomeActive(_ scene: UIScene) {
    
  }
  
  func sceneWillResignActive(_ scene: UIScene) {
    
  }
  
  func sceneWillEnterForeground(_ scene: UIScene) {
    
  }
  
  func sceneDidEnterBackground(_ scene: UIScene) {
    
  }
  
  
}

