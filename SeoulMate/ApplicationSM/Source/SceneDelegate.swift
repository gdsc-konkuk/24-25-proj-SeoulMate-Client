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
    
    appDIContainer = AppDIContainer()
    
    UserSessionManager.shared.appDIContainer = appDIContainer
    
    window = UIWindow(windowScene: windowScene)
    
    // TODO: 시연을 위해
    showLoginScreen()
    // TODO: Fix UserSession Manager
//    if UserSessionManager.shared.isLoggedIn {
//      showLoginScreen()
//      // showMainTabBar()
//    } else {
//      showLoginScreen()
//    }
    
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
  
  // 온보딩 화면으로 이동하는 메서드 추가
  func showOnboardingScreen() {
    let loginSceneDIContainer = appDIContainer.makeLoginSceneDIContainer()
    let travelWithVC = loginSceneDIContainer.makeTravelWithViewController()
    
    // 이미 navigationController가 있는 경우를 체크
    if let existingNavController = window?.rootViewController as? UINavigationController {
      // 기존 navigationController에 push
      existingNavController.pushViewController(travelWithVC, animated: true)
    } else {
      // 새로운 navigationController 생성
      let navigationController = UINavigationController(rootViewController: travelWithVC)
      window?.rootViewController = navigationController
    }
    window?.makeKeyAndVisible()
  }
}
