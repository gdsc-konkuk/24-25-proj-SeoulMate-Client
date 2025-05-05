//
//  TravelWithViewController.swift
//  SeoulMate
//
//  Created by 박성근 on 4/7/25.
//

import UIKit
import Combine
import SnapKit
import SwiftUI

final class TravelWithViewController: UIViewController {
  
  // MARK: - Properties
  private let companions = TravelPreferences.companions
  
  @Published private var selectedCompanion: String?
  private var subscriptions = Set<AnyCancellable>()
  
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
    button.tintColor = .gray900
    return button
  }()
  
  private let stepCountLabel: UILabel = {
    let label = UILabel()
    label.text = "1/2"
    label.font = .mediumFont(ofSize: 20)
    label.textColor = .gray400
    return label
  }()
  
  private let titleLabel: UILabel = {
    let label = UILabel()
    label.text = "Let's Start!"
    label.font = .boldFont(ofSize: 24)
    label.textColor = .gray900
    return label
  }()
  
  private let progressBar: UIProgressView = {
    let progressBar = UIProgressView()
    progressBar.progressTintColor = .main500
    progressBar.trackTintColor = .gray200
    progressBar.progress = 0.5
    return progressBar
  }()
  
  private let subtitleLabel: UILabel = {
    let label = UILabel()
    label.text = "Who are you traveling with?"
    label.font = .mediumFont(ofSize: 18)
    label.textColor = .gray900
    return label
  }()
  
  private lazy var companionStackView: DynamicStackView = {
    let stackView = DynamicStackView()
    stackView.isSingleSelectionMode = true
    stackView.buttonFont = .mediumFont(ofSize: 16)
    return stackView
  }()
  
  private let nextButton: CommonRectangleButton = {
    let button = CommonRectangleButton(
      title: "Next",
      fontStyle: .boldFont(ofSize: 18),
      titleColor: .gray400,
      backgroundColor: .gray200
    )
    button.isEnabled = false
    button.alpha = 0.5
    return button
  }()
  
  // MARK: - LifeCycle
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    setupCompanionStackView()
    setupConstraints()
    setupActions()
    setupBindings()
  }
}

extension TravelWithViewController {
  private func setupUI() {
    view.backgroundColor = .white
    
    let spacer = UIView()
    spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
    spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    
    navigationBarStackView.addArrangedSubview(backButton)
    navigationBarStackView.addArrangedSubview(spacer)
    navigationBarStackView.addArrangedSubview(stepCountLabel)
    
    view.addSubview(navigationBarStackView)
    view.addSubview(titleLabel)
    view.addSubview(progressBar)
    view.addSubview(subtitleLabel)
    view.addSubview(companionStackView)
    view.addSubview(nextButton)
    
    view.backgroundColor = .white
  }
  
  private func setupCompanionStackView() {
    companionStackView.setItems(companions)
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
    
    titleLabel.snp.makeConstraints { make in
      make.top.equalTo(backButton.snp.bottom).offset(30)
      make.leading.equalToSuperview().offset(20)
      make.height.equalTo(26)
    }
    
    progressBar.snp.makeConstraints { make in
      make.top.equalTo(titleLabel.snp.bottom).offset(20)
      make.leading.equalToSuperview().offset(20)
      make.trailing.equalToSuperview().offset(-20)
      make.height.equalTo(3)
    }
    
    subtitleLabel.snp.makeConstraints { make in
      make.top.equalTo(progressBar.snp.bottom).offset(14)
      make.leading.equalToSuperview().offset(20)
    }
    
    companionStackView.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(UIApplication.screenHeight * 0.3)
      make.leading.equalToSuperview().offset(20)
      //      make.height.equalTo(100)
    }
    
    nextButton.snp.makeConstraints { make in
      make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20)
      make.leading.equalToSuperview().offset(20)
      make.trailing.equalToSuperview().offset(-20)
      make.height.equalTo(56)
    }
  }
  
  private func setupActions() {
    backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
    nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
  }
  
  private func setupBindings() {
    companionStackView.selectionPublisher
      .sink { [weak self] selectedItem in
        guard let self = self else { return }
        
        if selectedItem.isSelected {
          self.selectedCompanion = selectedItem.title
        } else {
          self.selectedCompanion = nil
        }
      }
      .store(in: &subscriptions)
    
    $selectedCompanion
      .map { $0 != nil }
      .sink { [weak self] isEnabled in
        guard let self = self else { return }
        self.nextButton.isEnabled = isEnabled
        self.nextButton.alpha = isEnabled ? 1.0 : 0.5
        self.nextButton.backgroundColor = isEnabled ? .main500 : .gray200
        self.nextButton.setTitleColor(isEnabled ? .white : .gray400, for: .normal)
      }
      .store(in: &subscriptions)
  }
}

// MARK: - Action Methods
extension TravelWithViewController {
  @objc private func backButtonTapped() {
    navigationController?.popViewController(animated: true)
  }
  
  @objc private func nextButtonTapped() {
    guard let selectedCompanion = selectedCompanion else { return }
    
    guard let appDIContainer = UserSessionManager.shared.appDIContainer else { return }
    let loginSceneDIContainer = appDIContainer.makeLoginSceneDIContainer()
    let travelPurposeVC = loginSceneDIContainer.makeTravelPurposeViewController(
      travelCompanion: selectedCompanion
    )
    navigationController?.pushViewController(travelPurposeVC, animated: true)
  }
}
