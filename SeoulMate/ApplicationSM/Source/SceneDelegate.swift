//
//  SceneDelegate.swift
//  SeoulMate
//
//  Created by 박성근 on 3/27/25.
//

import UIKit
import Combine
import GooglePlaces

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  
  var window: UIWindow?
  private var cancellables = Set<AnyCancellable>()
  
  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = (scene as? UIWindowScene) else { return }
    
    // DIContainer에 의존성 등록
    registerDependencies()
    
    let window = UIWindow(windowScene: windowScene)
    self.window = window
    
    // 현재는 토큰 검증 로직이 주석 처리되어 있으므로 TabBarController로 바로 이동
    window.rootViewController = TabBarController()
    
    // 토큰 유효성 검사 코드 (필요시 주석 해제)
    /*
     let tokenStorage = DIContainer.shared.resolve(type: TokenStorageProtocol.self)!
     
     if tokenStorage.isTokenValid() {
     토큰이 유효하다면 TabBarController로 이동
     window.rootViewController = TabBarController()
     } else if let refreshToken = tokenStorage.getRefreshToken() {
     토큰 갱신 시도
     refreshTokenAndNavigate(window: window, refreshToken: refreshToken)
     } else {
     로그인 화면으로 이동
     window.rootViewController = LoginViewController()
     }
     */
    
    window.makeKeyAndVisible()
  }
  
  private func registerDependencies() {
    DIContainer.shared.registerNetworkDependencies()
    DIContainer.shared.registerAuthDependencies()
    DIContainer.shared.registerPlacesDependencies()
  }
  
  private func refreshTokenAndNavigate(window: UIWindow, refreshToken: String) {
    // 로딩 화면 표시
    let loadingViewController = UIViewController()
    let activityIndicator = UIActivityIndicatorView(style: .large)
    activityIndicator.center = loadingViewController.view.center
    activityIndicator.startAnimating()
    loadingViewController.view.addSubview(activityIndicator)
    loadingViewController.view.backgroundColor = .systemBackground
    
    window.rootViewController = loadingViewController
    
    let loginUseCase = DIContainer.shared.resolve(type: LoginUseCaseProtocol.self)!
    
    // 토큰 갱신 요청
    loginUseCase.executeTokenRefresh()
      .receive(on: DispatchQueue.main)
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            // 성공적으로 토큰 갱신 시 TabBarController로 이동
            window.rootViewController = TabBarController()
          case .failure:
            // 실패 시 로그인 화면으로 이동
            window.rootViewController = LoginViewController()
          }
        },
        receiveValue: { _ in }
      )
      .store(in: &cancellables)
  }
  
  func sceneDidDisconnect(_ scene: UIScene) {}
  
  func sceneDidBecomeActive(_ scene: UIScene) {}
  
  func sceneWillResignActive(_ scene: UIScene) {}
  
  func sceneWillEnterForeground(_ scene: UIScene) {}
  
  func sceneDidEnterBackground(_ scene: UIScene) {}
}
