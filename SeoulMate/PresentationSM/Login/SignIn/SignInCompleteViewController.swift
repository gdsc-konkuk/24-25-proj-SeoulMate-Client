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
  private let navigationBarStackView: UIStackView = {
    let stackView = UIStackView()
    stackView.axis = .horizontal
    stackView.alignment = .center
    stackView.distribution = .fill
    return stackView
  }()
  
  private let backButton: UIButton = {
    let button = UIButton()
    button.setImage(UIImage(systemName: "arrow.left"), for: .normal)
    button.tintColor = .black
    return button
  }()
  
  private let circleView: UIView = {
    let view = UIView()
    view.backgroundColor = .main100
    view.layer.cornerRadius = 50
    return view
  }()
  
  private let checkmarkImageView: UIImageView = {
    let imageView = UIImageView()
    let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .bold)
    let image = UIImage(systemName: "checkmark", withConfiguration: config)
    imageView.image = image
    imageView.tintColor = .main500
    imageView.contentMode = .scaleAspectFit
    return imageView
  }()
  
  private let titleLabel: UILabel = {
    let label = UILabel()
    label.font = .boldFont(ofSize: 20)
    label.textColor = .black
    label.textAlignment = .center
    label.text = "Completed!"
    return label
  }()
  
  private let nextButton: UIButton = {
    let button = UIButton()
    button.setTitle("Let's start", for: .normal)
    button.titleLabel?.font = .boldFont(ofSize: 18)
    button.backgroundColor = .main500
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
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(true, animated: false)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    navigationController?.setNavigationBarHidden(false, animated: false)
  }
}

// MARK: - UI Setup
extension SignInCompleteViewController {
  private func setupUI() {
    view.backgroundColor = .gray50
    
    let spacer = UIView()
    spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
    spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    
    navigationBarStackView.addArrangedSubview(backButton)
    navigationBarStackView.addArrangedSubview(spacer)
    
    view.addSubview(navigationBarStackView)
    view.addSubview(circleView)
    circleView.addSubview(checkmarkImageView)
    view.addSubview(titleLabel)
    view.addSubview(nextButton)
    view.addSubview(bottomIndicator)
  }
  
  private func setupConstraints() {
    navigationBarStackView.snp.makeConstraints { make in
      make.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(20)
      make.leading.equalToSuperview().offset(20)
      make.trailing.equalToSuperview().offset(-20)
      make.height.equalTo(24)
    }
    
    backButton.snp.makeConstraints { make in
      make.width.height.equalTo(24)
    }
    
    circleView.snp.makeConstraints { make in
      make.top.equalTo(navigationBarStackView.snp.bottom).offset(UIApplication.screenHeight * 0.2)
      make.centerX.equalToSuperview()
      make.width.height.equalTo(100)
    }
    
    checkmarkImageView.snp.makeConstraints { make in
      make.center.equalTo(circleView)
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
    backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
    nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
  }
}

// MARK: - Actions
extension SignInCompleteViewController {
  @objc private func backButtonTapped() {
    navigationController?.popViewController(animated: true)
  }
  
  @objc private func nextButtonTapped() {
    // 온보 딩 완료 처리 및 메인 화면으로 이동
    UserSessionManager.shared.completeOnboardingAndNavigateToMain()
  }
}
