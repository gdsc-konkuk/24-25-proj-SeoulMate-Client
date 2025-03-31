//
//  SceneDelegate.swift
//  SeoulMate
//
//  Created by 박성근 on 3/27/25.
//

import UIKit
import Combine

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  
  var window: UIWindow?
  private var cancellables = Set<AnyCancellable>()
  
  // DI 컨테이너
  private lazy var tokenStorage: TokenStorageProtocol = {
    return KeychainTokenStorage()
  }()
  
  private lazy var networkService: NetworkServiceProtocol = {
    return NetworkService(tokenStorage: tokenStorage)
  }()
  
  private lazy var authRepository: AuthRepositoryProtocol = {
    // Config.xcconfig에서 설정한 BASE_URL
    // TODO: Base URL에 맞게 수정
    let baseURL = Bundle.main.infoDictionary?["BASE_URL"] as? String ?? "https://api.seoulmate.com"
    return AuthRepository(networkService: networkService, baseURL: baseURL)
  }()
  
  private lazy var loginUseCase: LoginUseCaseProtocol = {
    return LoginUseCase(authRepository: authRepository, tokenStorage: tokenStorage)
  }()
  
  private lazy var googleAuthService: GoogleAuthServiceProtocol = {
    return GoogleAuthService()
  }()
  
  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = (scene as? UIWindowScene) else { return }
    
    let window = UIWindow(windowScene: windowScene)
    self.window = window
    
    // 토큰 유효성 검사
    if tokenStorage.isTokenValid() {
      // 토큰이 유효하다면 TabBarController로 이동
      window.rootViewController = TabBarController()
    } else if let refreshToken = tokenStorage.getRefreshToken() {
      // 토큰 갱신 시도
      refreshTokenAndNavigate(window: window, refreshToken: refreshToken)
    } else {
      // 로그인 화면으로 이동
      let loginViewController = LoginViewController(
        loginUseCase: loginUseCase,
        googleAuthService: googleAuthService
      )
      window.rootViewController = loginViewController
    }
    
    window.makeKeyAndVisible()
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
    
    // 토큰 갱신 요청
    loginUseCase.executeTokenRefresh()
      .receive(on: DispatchQueue.main)
      .sink(
        receiveCompletion: { [weak self] completion in
          switch completion {
          case .finished:
            // 성공적으로 토큰 갱신 시 TabBarController로 이동
            window.rootViewController = TabBarController()
          case .failure:
            // 실패 시 로그인 화면으로 이동
            guard let self = self else { return }
            window.rootViewController = LoginViewController(
              loginUseCase: self.loginUseCase,
              googleAuthService: self.googleAuthService
            )
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
