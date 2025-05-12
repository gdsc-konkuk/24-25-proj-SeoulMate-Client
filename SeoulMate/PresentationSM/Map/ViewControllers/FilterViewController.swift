//
//  FilterViewController.swift
//  SeoulMate
//
//  Created by 박성근 on 5/3/25.
//

import UIKit
import Combine
import SnapKit

// MARK: - FilterDelegate
protocol FilterDelegate: AnyObject {
  func didApplyFilter(_ filterData: FilterData)
}

final class FilterViewController: UIViewController {
  
  // MARK: - Properties
  private let getUserProfileUseCase: GetUserProfileUseCaseProtocol
  private let updateUserProfileUseCase: UpdateUserProfileUseCaseProtocol
  private var cancellables = Set<AnyCancellable>()
  
  private let travelCompanions = TravelPreferences.companions
  private let travelPurposes = TravelPreferences.purposes
  
  @Published private var selectedCompanion: String?
  @Published private var selectedPurposes: [String] = []
  private var subscriptions = Set<AnyCancellable>()
  
  weak var delegate: FilterDelegate?
  
  // MARK: - UI Properties
  private let navigationBarView: UIView = {
    let view = UIView()
    view.backgroundColor = .white
    return view
  }()
  
  private let backButton: UIButton = {
    let button = UIButton()
    button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
    button.tintColor = .black
    return button
  }()
  
  private let titleLabel: UILabel = {
    let label = UILabel()
    label.text = "Filter"
    label.font = .boldSystemFont(ofSize: 20)
    label.textColor = .black
    return label
  }()
  
  private let clearAllButton: UIButton = {
    let button = UIButton()
    button.setTitle("Clear all", for: .normal)
    button.setTitleColor(.systemBlue, for: .normal)
    button.titleLabel?.font = .systemFont(ofSize: 16)
    return button
  }()
  
  private let scrollView: UIScrollView = {
    let scrollView = UIScrollView()
    scrollView.showsVerticalScrollIndicator = false
    return scrollView
  }()
  
  private let contentView: UIView = {
    let view = UIView()
    return view
  }()
  
  private let travelingWithLabel: UILabel = {
    let label = UILabel()
    label.text = "Traveling with..."
    label.font = .boldSystemFont(ofSize: 24)
    label.textColor = .black
    return label
  }()
  
  private lazy var companionStackView: DynamicStackView = {
    let stackView = DynamicStackView()
    stackView.isSingleSelectionMode = true  // 단일 선택
    stackView.buttonFont = .mediumFont(ofSize: 16)
    stackView.buttonHeight = 40
    stackView.buttonCornerRadius = 20
    stackView.buttonVerticalPadding = 10
    stackView.buttonHorizontalPadding = 18
    stackView.horizontalSpacing = 8
    stackView.verticalSpacing = 12
    return stackView
  }()
  
  private let travelingForLabel: UILabel = {
    let label = UILabel()
    label.text = "Traveling for.."
    label.font = .boldSystemFont(ofSize: 24)
    label.textColor = .black
    return label
  }()
  
  private lazy var purposeStackView: DynamicStackView = {
    let stackView = DynamicStackView()
    stackView.isSingleSelectionMode = false  // 다중 선택
    stackView.buttonFont = .mediumFont(ofSize: 16)
    stackView.buttonHeight = 40
    stackView.buttonCornerRadius = 20
    stackView.buttonVerticalPadding = 10
    stackView.buttonHorizontalPadding = 18
    stackView.horizontalSpacing = 8
    stackView.verticalSpacing = 12
    return stackView
  }()
  
  private let applyButton: UIButton = {
    let button = UIButton()
    button.setTitle("Apply filters", for: .normal)
    button.setTitleColor(.white, for: .normal)
    button.titleLabel?.font = .boldSystemFont(ofSize: 18)
    button.backgroundColor = .systemBlue
    button.layer.cornerRadius = 25
    return button
  }()
  
  // MARK: - Initializer
  init(
    getUserProfileUseCase: GetUserProfileUseCaseProtocol,
    updateUserProfileUseCase: UpdateUserProfileUseCaseProtocol
  ) {
    self.getUserProfileUseCase = getUserProfileUseCase
    self.updateUserProfileUseCase = updateUserProfileUseCase
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    setupConstraints()
    setupActions()
    setupBindings()
    setupStackViews()
    
    // 프로필은 뷰가 처음 로드될 때만 가져옴
    loadUserProfile()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(true, animated: animated)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    navigationController?.setNavigationBarHidden(false, animated: animated)
  }
  
  // MARK: - Setup Methods
  private func setupUI() {
    view.backgroundColor = .white
    
    view.addSubview(navigationBarView)
    navigationBarView.addSubview(backButton)
    navigationBarView.addSubview(titleLabel)
    navigationBarView.addSubview(clearAllButton)
    
    view.addSubview(scrollView)
    scrollView.addSubview(contentView)
    
    contentView.addSubview(travelingWithLabel)
    contentView.addSubview(companionStackView)
    contentView.addSubview(travelingForLabel)
    contentView.addSubview(purposeStackView)
    
    view.addSubview(applyButton)
  }
  
  private func setupConstraints() {
    navigationBarView.snp.makeConstraints { make in
      make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
      make.height.equalTo(44)
    }
    
    backButton.snp.makeConstraints { make in
      make.leading.equalToSuperview().offset(16)
      make.centerY.equalToSuperview()
      make.width.height.equalTo(24)
    }
    
    titleLabel.snp.makeConstraints { make in
      make.center.equalToSuperview()
    }
    
    clearAllButton.snp.makeConstraints { make in
      make.trailing.equalToSuperview().offset(-16)
      make.centerY.equalToSuperview()
    }
    
    scrollView.snp.makeConstraints { make in
      make.top.equalTo(navigationBarView.snp.bottom)
      make.leading.trailing.equalToSuperview()
      make.bottom.equalTo(applyButton.snp.top).offset(-16)
    }
    
    contentView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
      make.width.equalTo(scrollView)
    }
    
    travelingWithLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(24)
      make.leading.equalToSuperview().offset(20)
    }
    
    companionStackView.snp.makeConstraints { make in
      make.top.equalTo(travelingWithLabel.snp.bottom).offset(20)
      make.leading.equalToSuperview().offset(20)
      make.trailing.equalToSuperview().offset(-20)
    }
    
    travelingForLabel.snp.makeConstraints { make in
      make.top.equalTo(companionStackView.snp.bottom).offset(40)
      make.leading.equalToSuperview().offset(20)
    }
    
    purposeStackView.snp.makeConstraints { make in
      make.top.equalTo(travelingForLabel.snp.bottom).offset(20)
      make.leading.equalToSuperview().offset(20)
      make.trailing.equalToSuperview().offset(-20)
      make.bottom.equalToSuperview().offset(-20)
    }
    
    applyButton.snp.makeConstraints { make in
      make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
      make.leading.equalToSuperview().offset(20)
      make.trailing.equalToSuperview().offset(-20)
      make.height.equalTo(50)
    }
  }
  
  private func setupStackViews() {
    companionStackView.setItems(travelCompanions)
    purposeStackView.setItems(travelPurposes)
  }
  
  private func setupActions() {
    backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
    clearAllButton.addTarget(self, action: #selector(clearAllButtonTapped), for: .touchUpInside)
    applyButton.addTarget(self, action: #selector(applyButtonTapped), for: .touchUpInside)
  }
  
  private func setupBindings() {
    // Companion 선택 변경 구독 (단일 선택)
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
    
    // Purpose 선택 변경 구독 (다중 선택)
    purposeStackView.selectionPublisher
      .sink { [weak self] selectedItem in
        guard let self = self else { return }
        
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
    
    // Purpose 선택된 인덱스 집합 변경 구독
    purposeStackView.selectedIndicesPublisher
      .map { indices -> [String] in
        indices.compactMap { index in
          guard index < self.travelPurposes.count else { return nil }
          return self.travelPurposes[index]
        }.sorted()
      }
      .assign(to: \.selectedPurposes, on: self)
      .store(in: &subscriptions)
  }
  
  // 사용자 프로필 정보 로드
  private func loadUserProfile() {
    print("🔍 loadUserProfile called")
    getUserProfileUseCase.execute()
      .receive(on: DispatchQueue.main)
      .sink { completion in
        switch completion {
        case .finished:
          print("✅ Profile load finished")
        case .failure(let error):
          print("❌ Failed to load profile: \(error)")
        }
      } receiveValue: { [weak self] profile in
        print("📦 Received profile: \(profile)")
        self?.updateUIWithProfile(profile)
      }
      .store(in: &cancellables)
  }
  
  private func updateUIWithProfile(_ profile: UserProfileResponse) {
    // 기존 선택 사항 표시
    if let companionIndex = travelCompanions.firstIndex(of: profile.companion) {
      companionStackView.selectItem(at: companionIndex)
      selectedCompanion = profile.companion
    }
    
    // purposes 복원
    if let purposes = profile.purpose {
      for purpose in purposes {
        if let purposeIndex = travelPurposes.firstIndex(of: purpose) {
          purposeStackView.selectItem(at: purposeIndex)
        }
      }
      selectedPurposes = purposes
    }
  }
  
  // MARK: - Action Methods
  @objc private func backButtonTapped() {
    dismiss(animated: true)
  }
  
  @objc private func clearAllButtonTapped() {
    // 모든 선택 초기화
    companionStackView.clearSelection()
    purposeStackView.clearSelection()
    selectedCompanion = nil
    selectedPurposes = []
  }
  
  @objc private func applyButtonTapped() {
    let filterData = FilterData(
      companion: selectedCompanion,
      purposes: selectedPurposes
    )
    
    // 필터 데이터 저장
    saveFilterData(filterData)
    
    // delegate에 알림
    delegate?.didApplyFilter(filterData)
    dismiss(animated: true)
  }
  
  private func saveFilterData(_ filterData: FilterData) {
    // 현재 프로필 가져오기
    getUserProfileUseCase.execute()
      .flatMap { [weak self] profile -> AnyPublisher<Void, NetworkError> in
        guard let self = self else {
          return Fail(error: NetworkError.unknown(NSError())).eraseToAnyPublisher()
        }
        
        // 프로필 업데이트
        return self.updateUserProfileUseCase.execute(
          userName: profile.name,
          // TODO: 일단 birthYear는 필요x -> 그냥 막 쏠 예정
          birthYear: "2020-08-01",
          companion: filterData.companion ?? profile.companion,
          purposes: filterData.purposes.isEmpty ? (profile.purpose ?? []) : filterData.purposes
        )
      }
      .receive(on: DispatchQueue.main)
      .sink { completion in
        switch completion {
        case .finished:
          print("Filter data saved successfully")
        case .failure(let error):
          print("Failed to save filter data: \(error)")
        }
      } receiveValue: { _ in }
      .store(in: &cancellables)
  }
}
