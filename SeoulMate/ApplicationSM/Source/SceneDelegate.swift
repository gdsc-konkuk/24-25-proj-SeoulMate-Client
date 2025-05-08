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
  var appDIContainer: AppDIContainer!  // private에서 internal로 변경
  
  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = (scene as? UIWindowScene) else { return }
    
    // Create AppDIContainer
    appDIContainer = AppDIContainer()
    
    // UserSessionManager에 AppDIContainer 설정
    UserSessionManager.shared.appDIContainer = appDIContainer
    
    window = UIWindow(windowScene: windowScene)
    
    // MARK: 백엔드 서버 구현시
    if UserSessionManager.shared.isLoggedIn {
      showMainTabBar()
    } else {
      showLoginScreen()
    }
    
    window?.makeKeyAndVisible()
  }
  
  private func showLoginScreen() {
    let loginSceneDIContainer = appDIContainer.makeLoginSceneDIContainer()
    let loginViewController = loginSceneDIContainer.makeSocialLoginViewController()
    let navigationController = UINavigationController(rootViewController: loginViewController)
    window?.rootViewController = navigationController
  }
  
  private func showMainTabBar() {
    let tabBarController = TabBarController(appDIContainer: appDIContainer)
    window?.rootViewController = tabBarController
  }
}
