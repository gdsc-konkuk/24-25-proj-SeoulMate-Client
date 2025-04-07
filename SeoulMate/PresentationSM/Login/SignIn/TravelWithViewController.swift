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
  private let companions = [
    "혼자", "친구랑", "연인이랑", "가족이랑", "여행", "출장/업무"
  ]
  
  @Published private var selectedCompanion: String?
  private var subscriptions = Set<AnyCancellable>()
  
  // MARK: - UI Properties
  private let progressBar: UIProgressView = {
    let progressBar = UIProgressView()
    progressBar.progressTintColor = .black
    progressBar.trackTintColor = .lightGray
    progressBar.progress = 0.5
    return progressBar
  }()
  
  private let backButton: UIButton = {
    let button = UIButton()
    button.setImage(UIImage(systemName: "arrow.left"), for: .normal)
    button.tintColor = .black
    return button
  }()
  
  private let titleLabel: UILabel = {
    let label = UILabel()
    label.text = "누구랑 여행하는지"
    label.font = .boldFont(ofSize: 22)
    label.textColor = .black
    return label
  }()
  
  private let subtitleLabel: UILabel = {
    let label = UILabel()
    label.text = "Descripton"
    label.font = .mediumFont(ofSize: 16)
    label.textColor = .darkGray
    return label
  }()
  
  private lazy var companionStackView: DynamicStackView = {
    let stackView = DynamicStackView()
    stackView.normalBackgroundColor = .white
    stackView.selectedBackgroundColor = .black
    stackView.normalTextColor = .darkGray
    stackView.selectedTextColor = .white
    stackView.maxWidth = view.frame.width - 40
    stackView.isSingleSelectionMode = true
    return stackView
  }()
  
  private let nextButton: CommonRectangleButton = {
    let button = CommonRectangleButton(
      title: "Next",
      fontStyle: .boldFont(ofSize: 18),
      titleColor: .darkGray,
      backgroundColor: .lightGray
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
    view.addSubview(progressBar)
    view.addSubview(backButton)
    view.addSubview(titleLabel)
    view.addSubview(subtitleLabel)
    view.addSubview(companionStackView)
    view.addSubview(nextButton)
    
    view.backgroundColor = .white
  }
  
  private func setupCompanionStackView() {
    companionStackView.setItems(companions)
  }
  
  private func setupConstraints() {
    progressBar.snp.makeConstraints { make in
      make.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(20)
      make.leading.equalToSuperview().offset(20)
      make.trailing.equalToSuperview().offset(-20)
      make.height.equalTo(3)
    }
    
    backButton.snp.makeConstraints { make in
      make.top.equalTo(progressBar.snp.bottom).offset(30)
      make.leading.equalToSuperview().offset(20)
      make.width.height.equalTo(24)
    }
    
    titleLabel.snp.makeConstraints { make in
      make.top.equalTo(backButton.snp.bottom).offset(30)
      make.leading.equalToSuperview().offset(20)
      make.height.equalTo(26)
    }
    
    subtitleLabel.snp.makeConstraints { make in
      make.top.equalTo(titleLabel.snp.bottom).offset(14)
      make.leading.equalToSuperview().offset(20)
    }
    
    companionStackView.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(UIApplication.screenHeight * 0.3)
      make.leading.equalToSuperview().offset(20)
      make.height.equalTo(100)
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
        self.nextButton.backgroundColor = isEnabled ? .black : .lightGray
        self.nextButton.setTitleColor(isEnabled ? .white : .darkGray, for: .normal)
      }
      .store(in: &subscriptions)
  }
  
  private func updateNextButton() {
    if selectedCompanion != nil {
      nextButton.backgroundColor = .black
      nextButton.titleLabel?.textColor = .white
      nextButton.isEnabled = true
      nextButton.alpha = 1.0
    } else {
      nextButton.backgroundColor = .lightGray
      nextButton.titleLabel?.textColor = .darkGray
      nextButton.isEnabled = false
      nextButton.alpha = 0.5
    }
  }
}

// MARK: - Action Methods
extension TravelWithViewController {
  @objc private func backButtonTapped() {
    navigationController?.popViewController(animated: true)
  }
  
  @objc private func nextButtonTapped() {
    // TODO: pushViewController with data
    guard let selectedCompanion = selectedCompanion else { return }
    
    // TravelPurposeViewController로 이동
    let travelPurposeVC = TravelPurposeViewController(travelCompanion: selectedCompanion)
    navigationController?.pushViewController(travelPurposeVC, animated: true)
  }
}
