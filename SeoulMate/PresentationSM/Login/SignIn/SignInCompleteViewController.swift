//
//  SignInCompleteViewController.swift
//  SeoulMate
//
//  Created on 4/8/25.
//

import UIKit
import SnapKit

final class SignInCompleteViewController: UIViewController {
  
  // MARK: - UI Properties
  private let circleView: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
    view.layer.cornerRadius = 50
    return view
  }()
  
  private let checkmarkImageView: UIImageView = {
    let imageView = UIImageView()
    let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .bold)
    let image = UIImage(systemName: "checkmark", withConfiguration: config)
    imageView.image = image
    imageView.tintColor = .black
    imageView.contentMode = .scaleAspectFit
    return imageView
  }()
  
  private let titleLabel: UILabel = {
    let label = UILabel()
    label.font = .boldFont(ofSize: 20)
    label.textColor = .black
    label.textAlignment = .center
    label.text = "생성 완료!"
    return label
  }()
  
  private let nextButton: UIButton = {
    let button = UIButton()
    button.setTitle("Next", for: .normal)
    button.titleLabel?.font = .boldFont(ofSize: 18)
    button.backgroundColor = .black
    button.setTitleColor(.white, for: .normal)
    button.layer.cornerRadius = 25
    return button
  }()
  
  private let bottomIndicator: UIView = {
    let view = UIView()
    view.backgroundColor = .black
    view.layer.cornerRadius = 2.5
    return view
  }()
  
  // MARK: - Properties
  
  // MARK: - Initializer
  
  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    setupConstraints()
    setupActions()
  }
}

// MARK: - UI Setup
extension SignInCompleteViewController {
  private func setupUI() {
    view.backgroundColor = .white
    
    view.addSubview(circleView)
    circleView.addSubview(checkmarkImageView)
    view.addSubview(titleLabel)
    view.addSubview(nextButton)
    view.addSubview(bottomIndicator)
  }
  
  private func setupConstraints() {
    circleView.snp.makeConstraints { make in
      make.center.equalToSuperview()
      make.width.height.equalTo(100)
    }
    
    checkmarkImageView.snp.makeConstraints { make in
      make.center.equalToSuperview()
      make.width.height.equalTo(40)
    }
    
    titleLabel.snp.makeConstraints { make in
      make.top.equalTo(circleView.snp.bottom).offset(20)
      make.centerX.equalToSuperview()
    }
    
    nextButton.snp.makeConstraints { make in
      make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-40)
      make.centerX.equalToSuperview()
      make.leading.equalToSuperview().offset(20)
      make.trailing.equalToSuperview().offset(-20)
      make.height.equalTo(50)
    }
    
    bottomIndicator.snp.makeConstraints { make in
      make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-10)
      make.centerX.equalToSuperview()
      make.width.equalTo(40)
      make.height.equalTo(5)
    }
  }
  
  private func setupActions() {
    nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
  }
}

// MARK: - Actions
extension SignInCompleteViewController {
  @objc private func nextButtonTapped() {
    // 온보딩 완료 처리
    UserSessionManager.shared.completeOnboarding()
    
    // 탭바 컨트롤러로 이동 (루트 컨트롤러로 설정)
    let tabBarController = TabBarController()
    
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let window = windowScene.windows.first {
      window.rootViewController = tabBarController
      window.makeKeyAndVisible()
    }
  }
}
