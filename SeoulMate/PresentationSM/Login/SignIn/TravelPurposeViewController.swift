//
//  TravelPurposeViewController.swift
//  SeoulMate
//
//  Created by 박성근 on 4/7/25.
//

import UIKit
import Combine
import SnapKit
import SwiftUI

final class TravelPurposeViewController: UIViewController {
  
  // MARK: - Properties
  private let travelCompanion: String
  
  private let purposes = [
    "관광", "쇼핑", "출장/업무"
  ]
  
  @Published private var selectedPurposes: [String] = []
  private var subscriptions = Set<AnyCancellable>()
  
  // MARK: - UI Properties
  private let progressBar: UIProgressView = {
    let progressBar = UIProgressView()
    progressBar.progressTintColor = .black
    progressBar.trackTintColor = .lightGray
    progressBar.progress = 1.0
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
    label.text = "여행 목적"
    label.font = .boldFont(ofSize: 22)
    label.textColor = .black
    return label
  }()
  
  private let subtitleLabel: UILabel = {
    let label = UILabel()
    label.text = "여행의 목적을 선택해주세요"
    label.font = .mediumFont(ofSize: 16)
    label.textColor = .darkGray
    return label
  }()
  
  private let infoLabel: UILabel = {
    let label = UILabel()
    label.text = "중복 선택 가능"
    label.font = .mediumFont(ofSize: 14)
    label.textColor = .lightGray
    return label
  }()
  
  private let selectedPurposesLabel: UILabel = {
    let label = UILabel()
    label.text = "선택한 목적: 없음"
    label.font = .mediumFont(ofSize: 14)
    label.textColor = .gray
    label.numberOfLines = 0
    return label
  }()
  
  private lazy var purposeStackView: DynamicStackView = {
    let stackView = DynamicStackView()
    stackView.normalBackgroundColor = .white
    stackView.selectedBackgroundColor = .black
    stackView.normalTextColor = .darkGray
    stackView.selectedTextColor = .white
    stackView.maxWidth = view.frame.width - 40
    stackView.isSingleSelectionMode = false // 다중 선택 모드로 설정
    return stackView
  }()
  
  private let nextButton: CommonRectangleButton = {
    let button = CommonRectangleButton(
      title: "다음",
      fontStyle: .boldFont(ofSize: 18),
      titleColor: .darkGray,
      backgroundColor: .lightGray
    )
    button.isEnabled = false
    button.alpha = 0.5
    return button
  }()
  
  // MARK: - Init
  // MARK: - Initializer
  init(travelCompanion: String) {
    self.travelCompanion = travelCompanion
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - LifeCycle
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    setupPurposeStackView()
    setupConstraints()
    setupActions()
    setupBindings()
  }
}

extension TravelPurposeViewController {
  private func setupUI() {
    view.backgroundColor = .white
    navigationController?.isNavigationBarHidden = true
    
    view.addSubview(progressBar)
    view.addSubview(backButton)
    view.addSubview(titleLabel)
    view.addSubview(infoLabel)
    view.addSubview(subtitleLabel)
    view.addSubview(purposeStackView)
    view.addSubview(selectedPurposesLabel)
    view.addSubview(nextButton)
  }
  
  private func setupPurposeStackView() {
    purposeStackView.setItems(purposes)
  }
  
  private func setupConstraints() {
    progressBar.snp.makeConstraints { make in
      make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
      make.leading.equalToSuperview().offset(20)
      make.trailing.equalToSuperview().offset(-20)
      make.height.equalTo(4)
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
    
    infoLabel.snp.makeConstraints { make in
      make.centerY.equalTo(titleLabel.snp.centerY)
      make.trailing.equalToSuperview().offset(-20)
    }
    
    subtitleLabel.snp.makeConstraints { make in
      make.top.equalTo(titleLabel.snp.bottom).offset(14)
      make.leading.equalToSuperview().offset(20)
    }
    
    purposeStackView.snp.makeConstraints { make in
      make.top.equalTo(subtitleLabel.snp.bottom).offset(40)
      make.leading.equalToSuperview().offset(20)
      make.trailing.equalToSuperview().offset(-20)
    }
    
    selectedPurposesLabel.snp.makeConstraints { make in
      make.top.equalTo(purposeStackView.snp.bottom).offset(20)
      make.leading.equalToSuperview().offset(20)
      make.trailing.equalToSuperview().offset(-20)
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
    // 스택뷰 선택 변경 이벤트 구독
    purposeStackView.selectionPublisher
      .sink { [weak self] selectedItem in
        guard let self = self else { return }
        
        // 선택 상태에 따라 처리
        if selectedItem.isSelected {
          if !self.selectedPurposes.contains(selectedItem.title) {
            self.selectedPurposes.append(selectedItem.title)
          }
        } else {
          if let idx = self.selectedPurposes.firstIndex(of: selectedItem.title) {
            self.selectedPurposes.remove(at: idx)
          }
        }
      }
      .store(in: &subscriptions)
    
    // 스택뷰 선택된 인덱스 집합 변경 구독
    purposeStackView.selectedIndicesPublisher
      .map { indices -> [String] in
        indices.compactMap { index in
          guard index < self.purposes.count else { return nil }
          return self.purposes[index]
        }.sorted()
      }
      .assign(to: \.selectedPurposes, on: self)
      .store(in: &subscriptions)
    
    // 선택된 목적 목록 변경 시 UI 업데이트
    $selectedPurposes
      .map { purposes -> String in
        purposes.isEmpty ? "선택한 목적: 없음" : "선택한 목적: \(purposes.joined(separator: ", "))"
      }
      .assign(to: \.text, on: selectedPurposesLabel)
      .store(in: &subscriptions)
    
    // 다음 버튼 활성화 상태 관리
    $selectedPurposes
      .map { !$0.isEmpty }
      .sink { [weak self] isEnabled in
        guard let self = self else { return }
        self.nextButton.isEnabled = isEnabled
        self.nextButton.alpha = isEnabled ? 1.0 : 0.5
        self.nextButton.backgroundColor = isEnabled ? .black : .lightGray
        self.nextButton.setTitleColor(isEnabled ? .white : .darkGray, for: .normal)
      }
      .store(in: &subscriptions)
  }
}

// MARK: - Action Methods
extension TravelPurposeViewController {
  @objc private func backButtonTapped() {
    navigationController?.popViewController(animated: true)
  }
  
  @objc private func nextButtonTapped() {
    // TODO: pushViewController with data
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
