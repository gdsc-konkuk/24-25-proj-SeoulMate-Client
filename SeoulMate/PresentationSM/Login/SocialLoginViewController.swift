//
//  SocialLoginViewController.swift
//  SeoulMate
//
//  Created by 박성근 on 4/7/25.
//

import UIKit
import SnapKit
import GoogleSignIn
import SwiftUI

final class SocialLoginViewController: UIViewController {
  
  // MARK: - Properties
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
    // 로딩 인디케이터 표시
    activityIndicator.startAnimating()
    googleSignInButton.isEnabled = false
    
    // UserSessionManager를 통한 Google 로그인 처리
    UserSessionManager.shared.startGoogleSignIn(presentingViewController: self) { [weak self] success in
      DispatchQueue.main.async {
        self?.activityIndicator.stopAnimating()
        self?.googleSignInButton.isEnabled = true
        
        if !success {
          self?.showLoginErrorAlert()
        }
      }
    }
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
