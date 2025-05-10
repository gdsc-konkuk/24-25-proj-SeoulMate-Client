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
  private let updateUserProfileUseCase: UpdateUserProfileUseCaseProtocol
  
  private let purposes = TravelPreferences.purposes
  @Published private var selectedPurposes: [String] = []
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
    button.tintColor = .black
    return button
  }()
  
  private let stepCountLabel: UILabel = {
    let label = UILabel()
    label.text = "2/2"
    label.font = .mediumFont(ofSize: 20)
    label.textColor = .gray400
    return label
  }()
  
  private let titleLabel: UILabel = {
    let label = UILabel()
    label.text = "Almost Done.."
    label.font = .boldFont(ofSize: 24)
    label.textColor = .gray900
    return label
  }()
  
  private let progressBar: UIProgressView = {
    let progressBar = UIProgressView()
    progressBar.progressTintColor = .main500
    progressBar.trackTintColor = .main500
    progressBar.progress = 1.0
    return progressBar
  }()
  
  private let subtitleLabel: UILabel = {
    let label = UILabel()
    label.text = "What style of travel are you planning to take?"
    label.font = .mediumFont(ofSize: 18)
    label.textColor = .gray900
    return label
  }()
  
  private let selectedPurposesLabel: UILabel = {
    let label = UILabel()
    label.text = "Selected Purpose: "
    label.font = .mediumFont(ofSize: 14)
    label.textColor = .gray
    label.numberOfLines = 0
    return label
  }()
  
  private lazy var purposeStackView: DynamicStackView = {
    let stackView = DynamicStackView()
    // MARK: 다중 선택 모드
    stackView.isSingleSelectionMode = false
    stackView.buttonFont = .mediumFont(ofSize: 16)
    stackView.buttonHeight = 40
    stackView.buttonCornerRadius = 20
    stackView.buttonVerticalPadding = 10
    stackView.buttonHorizontalPadding = 18
    stackView.horizontalSpacing = 8
    stackView.verticalSpacing = 12
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
  
  // MARK: - Initializer
  init(
    travelCompanion: String,
    updateUserProfileUseCase: UpdateUserProfileUseCaseProtocol
  ) {
    self.travelCompanion = travelCompanion
    self.updateUserProfileUseCase = updateUserProfileUseCase
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
    view.addSubview(purposeStackView)
    view.addSubview(selectedPurposesLabel)
    view.addSubview(nextButton)
  }
  
  private func setupPurposeStackView() {
    purposeStackView.setItems(purposes)
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
      make.top.equalTo(navigationBarStackView.snp.bottom).offset(30)
      make.leading.equalToSuperview().offset(20)
      make.height.equalTo(26)
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
        purposes.isEmpty ? "Selected Purpose: None" : "Selected Purpose: \(purposes.joined(separator: ", "))"
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
        self.nextButton.backgroundColor = isEnabled ? .main500 : .gray200
        self.nextButton.setTitleColor(isEnabled ? .white : .gray400, for: .normal)
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
    guard !selectedPurposes.isEmpty else { return }
    
    // 서버에 프로필 업데이트
    submitProfile()
  }
  
  private func submitProfile() {
    let userName = "New User"
    let birthYear = "2000"
    
    updateUserProfileUseCase.execute(
      userName: userName,
      birthYear: birthYear,
      companion: travelCompanion,  // 이전 화면에서 받은 데이터
      purposes: selectedPurposes   // 현재 화면에서 선택한 데이터
    )
    .receive(on: DispatchQueue.main)
    .sink { [weak self] completion in
      switch completion {
      case .finished:
        break
      case .failure(let error):
        print("프로필 업데이트 실패: \(error.localizedDescription)")
        self?.showErrorAlert()
      }
    } receiveValue: { [weak self] _ in
      // 성공 시 완료 화면으로 이동
      self?.navigateToCompleteScreen()
    }
    .store(in: &subscriptions)
  }
  
  private func navigateToCompleteScreen() {
    let signInVC = SignInCompleteViewController()
    navigationController?.pushViewController(signInVC, animated: true)
  }
  
  private func showErrorAlert() {
    let alert = UIAlertController(
      title: "오류",
      message: "프로필 정보 저장에 실패했습니다.",
      preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: "확인", style: .default))
    present(alert, animated: true)
  }
}
