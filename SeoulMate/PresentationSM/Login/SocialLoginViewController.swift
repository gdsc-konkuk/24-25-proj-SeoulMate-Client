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
  private let titleLabel: UILabel = {
    let label = UILabel()
    label.text = "SeoulMate"
    label.font = .boldFont(ofSize: 36)
    label.textColor = .black
    label.textAlignment = .center
    return label
  }()
  
  private let subtitleLabel: UILabel = {
    let label = UILabel()
    label.text = "서울 여행의 완벽한 파트너"
    label.font = .mediumFont(ofSize: 18)
    label.textColor = .darkGray
    label.textAlignment = .center
    return label
  }()
  
  // google login button
  private let googleSignInButton: GIDSignInButton = {
    let button = GIDSignInButton()
    button.style = .wide
    button.colorScheme = .light
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
    
    view.addSubview(titleLabel)
    view.addSubview(subtitleLabel)
    view.addSubview(googleSignInButton)
    view.addSubview(activityIndicator)
    
    titleLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(UIApplication.screenHeight * 0.3)
      make.centerX.equalToSuperview()
    }
    
    subtitleLabel.snp.makeConstraints { make in
      make.top.equalTo(titleLabel.snp.bottom).offset(12)
      make.centerX.equalToSuperview()
    }
    
    googleSignInButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-UIApplication.screenHeight * 0.15)
      make.centerX.equalToSuperview()
      make.width.equalTo(UIApplication.screenWidth * 0.7)
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
        print("Google 로그인 에러: \(error.localizedDescription)")
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
        
        print("ID Token: \(idToken)")  // 디버깅을 위해 ID 토큰 출력
        
        // UseCase를 통한 백엔드 로그인
        self.loginUseCase.execute(idToken: idToken)
          .receive(on: DispatchQueue.main)
          .sink { completion in
            switch completion {
            case .finished:
              break
            case .failure(let error):
              print("백엔드 로그인 실패: \(error.localizedDescription)")
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
    if response.isFirstLogin {
      UserSessionManager.shared.navigateToOnboarding()
    } else {
      UserSessionManager.shared.navigateToMain()
    }
  }
  
  private func handleLoginError() {
    activityIndicator.stopAnimating()
    googleSignInButton.isEnabled = true
    showLoginErrorAlert()
  }
  
  private func showLoginErrorAlert() {
    let alert = UIAlertController(
      title: "로그인 실패",
      message: "Google 로그인에 실패했습니다. 다시 시도해주세요.",
      preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: "확인", style: .default))
    present(alert, animated: true)
  }
}
