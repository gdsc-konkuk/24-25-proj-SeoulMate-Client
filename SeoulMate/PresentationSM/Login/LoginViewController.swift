//
//  LoginViewController.swift
//  SeoulMate
//
//  Created by 박성근 on 3/31/25.
//

import UIKit
import Combine
import SwiftUI

final class LoginViewController: UIViewController {
  
  // MARK: - Properties
  
  private let loginUseCase: LoginUseCaseProtocol
  private let googleAuthService: GoogleAuthServiceProtocol
  private var cancellables = Set<AnyCancellable>()
  
  // MARK: - UI Components
  
  private lazy var logoImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.image = UIImage(named: "AppLogo")
    imageView.contentMode = .scaleAspectFit
    imageView.translatesAutoresizingMaskIntoConstraints = false
    return imageView
  }()
  
  private lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.text = "SeoulMate"
    label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()
  
  private lazy var subtitleLabel: UILabel = {
    let label = UILabel()
    label.text = "서울의 모든 것을 경험하세요"
    label.font = UIFont.systemFont(ofSize: 16)
    label.textAlignment = .center
    label.textColor = .gray
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()
  
  private lazy var googleLoginButtonContainer: UIView = {
    let container = UIView()
    container.translatesAutoresizingMaskIntoConstraints = false
    return container
  }()
  
  // MARK: - Initialization
  
  init(
    loginUseCase: LoginUseCaseProtocol,
    googleAuthService: GoogleAuthServiceProtocol
  ) {
    self.loginUseCase = loginUseCase
    self.googleAuthService = googleAuthService
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Lifecycle Methods
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    setupSwiftUIButton()
  }
  
  // MARK: - Private Methods
  
  private func setupUI() {
    view.backgroundColor = .systemBackground
    
    view.addSubview(logoImageView)
    view.addSubview(titleLabel)
    view.addSubview(subtitleLabel)
    view.addSubview(googleLoginButtonContainer)
    
    NSLayoutConstraint.activate([
      logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
      logoImageView.widthAnchor.constraint(equalToConstant: 120),
      logoImageView.heightAnchor.constraint(equalToConstant: 120),
      
      titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 20),
      
      subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
      
      googleLoginButtonContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      googleLoginButtonContainer.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
      googleLoginButtonContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
      googleLoginButtonContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
      googleLoginButtonContainer.heightAnchor.constraint(equalToConstant: 60)
    ])
  }
  
  private func setupSwiftUIButton() {
    let googleButton = UIHostingController(rootView: GoogleSignInButton(action: googleLoginTapped))
    addChild(googleButton)
    googleLoginButtonContainer.addSubview(googleButton.view)
    googleButton.view.translatesAutoresizingMaskIntoConstraints = false
    
    NSLayoutConstraint.activate([
      googleButton.view.topAnchor.constraint(equalTo: googleLoginButtonContainer.topAnchor),
      googleButton.view.leadingAnchor.constraint(equalTo: googleLoginButtonContainer.leadingAnchor),
      googleButton.view.trailingAnchor.constraint(equalTo: googleLoginButtonContainer.trailingAnchor),
      googleButton.view.bottomAnchor.constraint(equalTo: googleLoginButtonContainer.bottomAnchor)
    ])
    
    googleButton.didMove(toParent: self)
  }
  
  private func googleLoginTapped() {
    startLoading()
    
    googleAuthService.signIn(presentingViewController: self)
      .flatMap { [weak self] tokens -> AnyPublisher<Void, Error> in
        guard let self = self else {
          return Fail(error: NSError(domain: "LoginViewController", code: -1, userInfo: nil)).eraseToAnyPublisher()
        }
        
        return self.loginUseCase.executeGoogleLogin(idToken: tokens.idToken, accessToken: tokens.accessToken)
          .mapError { $0 as Error }
          .eraseToAnyPublisher()
      }
      .receive(on: DispatchQueue.main)
      .sink(
        receiveCompletion: { [weak self] completion in
          self?.stopLoading()
          
          switch completion {
          case .finished:
            self?.navigateToMainScreen()
          case .failure(let error):
            self?.showError(error)
          }
        },
        receiveValue: { _ in }
      )
      .store(in: &cancellables)
  }
  
  private func navigateToMainScreen() {
    let tabBarController = TabBarController()
    tabBarController.modalPresentationStyle = .fullScreen
    present(tabBarController, animated: true)
  }
  
  private func showError(_ error: Error) {
    let alert = UIAlertController(
      title: "로그인 실패",
      message: "로그인에 실패했습니다. 다시 시도해주세요.\n오류: \(error.localizedDescription)",
      preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: "확인", style: .default))
    present(alert, animated: true)
  }
  
  private func startLoading() {
    // 로딩 인디케이터 표시
    let loadingView = UIActivityIndicatorView(style: .large)
    loadingView.startAnimating()
    loadingView.tag = 999
    loadingView.center = view.center
    view.addSubview(loadingView)
  }
  
  private func stopLoading() {
    // 로딩 인디케이터 제거
    if let loadingView = view.viewWithTag(999) as? UIActivityIndicatorView {
      loadingView.stopAnimating()
      loadingView.removeFromSuperview()
    }
  }
}

// MARK: - SwiftUI Google Sign-In Button

struct GoogleSignInButton: View {
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      HStack {
        Image("GoogleLogo")
          .resizable()
          .scaledToFit()
          .frame(width: 24, height: 24)
        
        Text("Google로 로그인")
          .font(.headline)
          .foregroundColor(.primary)
      }
      .frame(maxWidth: .infinity)
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 8)
          .strokeBorder(Color.gray.opacity(0.5), lineWidth: 1)
          .background(Color.white)
      )
      .cornerRadius(8)
    }
  }
}
