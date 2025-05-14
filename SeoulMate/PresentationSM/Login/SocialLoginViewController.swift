//
//  SocialLoginViewController.swift
//  SeoulMate
//
//  Created by 박성근 on 4/7/25.
//

import UIKit
import Combine
import SnapKit
import GoogleSignIn

final class SocialLoginViewController: UIViewController {
  
  // MARK: - Properties
  private let loginUseCase: LoginUseCaseProtocol
  private var cancellables = Set<AnyCancellable>()
  
  // MARK: - UI Properties
  private let titleImage: UIImageView = {
    let image = UIImageView()
    image.image = UIImage(named: "Union")
    return image
  }()
  
  private let titleLabel: UILabel = {
    let label = UILabel()
    label.text = "SeoulMate"
    label.font = .boldFont(ofSize: 40)
    label.textColor = .main500
    label.textAlignment = .center
    return label
  }()
  
  private let subtitleLabel: UILabel = {
    let label = UILabel()
    label.text = "Seoul's soulmate"
    label.font = .mediumFont(ofSize: 18)
    label.textColor = .darkGray
    label.textAlignment = .center
    return label
  }()

  private let buttonLabel: UILabel = {
    let label = UILabel()
    label.text = "Get started!"
    label.font = .mediumFont(ofSize: 18)
    label.textColor = .black
    label.textAlignment = .center
    return label
  }()
  
  // google login button
  private let googleSignInButton: GoogleSignInButton = {
    let button = GoogleSignInButton()
    return button
  }()
  
  // 로딩 인디케이터
  private let activityIndicator: UIActivityIndicatorView = {
    let indicator = UIActivityIndicatorView(style: .large)
    indicator.hidesWhenStopped = true
    indicator.color = .gray
    return indicator
  }()
  
  // MARK: - Initializer
  init(loginUseCase: LoginUseCaseProtocol) {
    self.loginUseCase = loginUseCase
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - LifeCycle
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    setupActions()
  }
}

extension SocialLoginViewController {
  private func setupUI() {
    view.backgroundColor = .white
    
    view.addSubview(titleImage)
    view.addSubview(titleLabel)
    view.addSubview(subtitleLabel)
    view.addSubview(buttonLabel)
    view.addSubview(googleSignInButton)
    view.addSubview(activityIndicator)
    
    titleImage.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(UIApplication.screenHeight * 0.25)
      make.centerX.equalToSuperview()
      make.width.equalTo(90)
      make.height.equalTo(120)
    }
    
    titleLabel.snp.makeConstraints { make in
      make.top.equalTo(titleImage.snp.bottom).offset(6)
      make.centerX.equalToSuperview()
    }
    
    subtitleLabel.snp.makeConstraints { make in
      make.top.equalTo(titleLabel.snp.bottom).offset(12)
      make.centerX.equalToSuperview()
    }
    
    buttonLabel.snp.makeConstraints { make in
      make.bottom.equalTo(googleSignInButton.snp.top).offset(-16)
      make.centerX.equalToSuperview()
    }
    
    googleSignInButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-UIApplication.screenHeight * 0.15)
      make.left.equalToSuperview().offset(20)
      make.right.equalToSuperview().offset(-20)
      make.height.equalTo(56)
    }
    
    activityIndicator.snp.makeConstraints { make in
      make.center.equalToSuperview()
    }
  }
  
  private func setupActions() {
    googleSignInButton.addTarget(self, action: #selector(handleGoogleSignIn), for: .touchUpInside)
  }
}

extension SocialLoginViewController {
  @objc private func handleGoogleSignIn() {
    activityIndicator.startAnimating()
    googleSignInButton.isEnabled = false
    
    // Google Sign-In
    GIDSignIn.sharedInstance.signIn(withPresenting: self) { [weak self] signInResult, error in
      guard let self = self else { return }
      
      if let error = error {
        Logger.log("Google 로그인 에러: \(error.localizedDescription)")
        self.handleLoginError()
        return
      }
      
      guard let signInResult = signInResult else {
        self.handleLoginError()
        return
      }
      
      // ID 토큰 갱신
      signInResult.user.refreshTokensIfNeeded { user, error in
        guard error == nil else {
          self.handleLoginError()
          return
        }
        
        guard let user = user,
              let idToken = user.idToken?.tokenString else {
          self.handleLoginError()
          return
        }
        
        Logger.log("ID Token: \(idToken)")  // 디버깅을 위해 ID 토큰 출력
        
        // UseCase를 통한 백엔드 로그인
        self.loginUseCase.execute(idToken: idToken)
          .receive(on: DispatchQueue.main)
          .sink { completion in
            switch completion {
            case .finished:
              break
            case .failure(let error):
              Logger.log("백엔드 로그인 실패: \(error.localizedDescription)")
              // Google Sign-Out 처리
              GIDSignIn.sharedInstance.signOut()
              self.handleLoginError()
            }
          } receiveValue: { [weak self] response in
            self?.handleLoginSuccess(response)
          }
          .store(in: &self.cancellables)
      }
    }
  }
  
  private func handleLoginSuccess(_ response: LoginResponse) {
    activityIndicator.stopAnimating()
    googleSignInButton.isEnabled = true
    
    // 토큰 저장
    UserSessionManager.shared.saveTokens(
      access: response.accessToken,
      refresh: response.refreshToken
    )
    UserSessionManager.shared.saveUserId(response.userId)
    
    // 첫 로그인 여부에 따라 화면 이동
//    if response.isFirstLogin {
//      // SceneDelegate를 통해 온보딩 화면으로 이동
//      if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
//        sceneDelegate.showOnboardingScreen()
//      }
//    } else {
//      UserSessionManager.shared.navigateToMain()
//    }
    if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
      sceneDelegate.showOnboardingScreen()
    }
  }
  
  private func handleLoginError() {
    activityIndicator.stopAnimating()
    googleSignInButton.isEnabled = true
    showLoginErrorAlert()
  }
  
  private func showLoginErrorAlert() {
    let alert = UIAlertController(
      title: "Login Failed",
      message: "Google login failed. Please try again.",
      preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
  }
}
