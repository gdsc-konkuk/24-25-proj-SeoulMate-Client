//
//  DynamicStackView.swift
//  SeoulMate
//
//  Created by 박성근 on 4/7/25.
//

import UIKit
import Combine
import SnapKit

final class DynamicStackView: UIStackView {
  
  // MARK: - Publisher
  let selectionPublisher = PassthroughSubject<(index: Int, title: String, isSelected: Bool), Never>()
  let selectedIndicesPublisher =  CurrentValueSubject<Set<Int>, Never>(Set<Int>())
  
  var verticalSpacing: CGFloat = 12
  var horizontalSpacing: CGFloat = 8
  var maxWidth: CGFloat = UIApplication.screenWidth - 40
  
  var buttons: [CommonRectangleButton] = []
  private var items: [String] = []
  private var horizontalStacks: [UIStackView] = []
  
  var isSingleSelectionMode: Bool = true {
    didSet {
      // 싱글 모드로 변경 시 기존 다중 선택 항목 초기화
      if isSingleSelectionMode && selectedIndicesPublisher.value.count > 1 {
        clearSelection()
      }
    }
  }
  
  // MARK: - UI Color
  var normalBackgroundColor: UIColor = .white
  var selectedBackgroundColor: UIColor = .main100
  var normalTextColor: UIColor = .gray500
  var selectedTextColor: UIColor = .main500
  
  // MARK: - Button Style
  var buttonFont: UIFont = .mediumFont(ofSize: 13) {
    didSet {
      updateButtonHeights()
    }
  }
  
  // 버튼 크기 관련
  var buttonHeight: CGFloat = 36
  var buttonCornerRadius: CGFloat = 8
  
  // 버튼 내부 여백
  var buttonVerticalPadding: CGFloat = 8
  var buttonHorizontalPadding: CGFloat = 12
  
  // 버튼 테두리
  var buttonBorderWidth: CGFloat = 1
  var normalBorderColor: UIColor = .gray500
  var selectedBorderColor: UIColor = .main500
  
  private var subscriptions = Set<AnyCancellable>()
  
  // MARK: - LifeCycle
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupStackView()
    setupBindings()
  }
  
  required init(coder: NSCoder) {
    super.init(coder: coder)
    setupStackView()
    setupBindings()
  }
  
  func setItems(_ items: [String]) {
    self.items = items
    
    // 기존 버튼과 스택 제거
    buttons.removeAll()
    horizontalStacks.forEach { $0.removeFromSuperview() }
    horizontalStacks.removeAll()
    
    // 새로운 버튼 생성 및 배치
    var currentHorizontalStack = createHorizontalStack()
    horizontalStacks.append(currentHorizontalStack)
    addArrangedSubview(currentHorizontalStack)
    
    var currentStackWidth: CGFloat = 0
    
    for (index, item) in items.enumerated() {
      let button = createButton(withTitle: item, at: index)
      button.sizeToFit()
      
      // 버튼 너비 + 여백이 최대 너비를 초과하면 새 행 생성
      let buttonWidth = button.intrinsicContentSize.width
      if currentStackWidth + buttonWidth > maxWidth && currentStackWidth > 0 {
        currentHorizontalStack = createHorizontalStack()
        horizontalStacks.append(currentHorizontalStack)
        addArrangedSubview(currentHorizontalStack)
        currentStackWidth = 0
      }
      
      currentHorizontalStack.addArrangedSubview(button)
      buttons.append(button)
      currentStackWidth += buttonWidth + horizontalSpacing
    }
    
    setNeedsLayout()
  }
  
  func getSelectedIndices() -> Set<Int> {
    return selectedIndicesPublisher.value
  }
  
  func getSelectedTitles() -> [String] {
    return getSelectedIndices().compactMap { index in
      guard index < items.count else { return nil }
      return items[index]
    }.sorted()
  }
  
  func selectItem(at index: Int) {
    guard index < buttons.count else { return }
    buttonTapped(buttons[index])
  }
  
  func clearSelection() {
    for button in buttons {
      button.backgroundColor = normalBackgroundColor
      button.setTitleColor(normalTextColor, for: .normal)
      button.layer.borderColor = UIColor.gray500.cgColor
      button.layer.borderWidth = 1
    }
    selectedIndicesPublisher.send(Set<Int>())
  }
}

extension DynamicStackView {
  private func setupBindings() {
    // 선택된 항목 변경 시 버튼 상태 동기화
    selectedIndicesPublisher
      .sink { [weak self] indices in
        guard let self = self else { return }
        
        // 모든 버튼 초기화
        for (buttonIndex, button) in self.buttons.enumerated() {
          if indices.contains(buttonIndex) {
            button.backgroundColor = self.selectedBackgroundColor
            button.setTitleColor(self.selectedTextColor, for: .normal)
            button.layer.borderColor = self.selectedBorderColor.cgColor
          } else {
            button.backgroundColor = self.normalBackgroundColor
            button.setTitleColor(self.normalTextColor, for: .normal)
            button.layer.borderColor = self.normalBorderColor.cgColor
          }
        }
      }
      .store(in: &subscriptions)
  }
  
  private func setupStackView() {
    self.axis = .vertical
    alignment = .leading
    spacing = verticalSpacing
    distribution = .fill
  }
  
  private func createButton(withTitle title: String, at index: Int) -> CommonRectangleButton {
    let button = CommonRectangleButton(
      title: title,
      fontStyle: buttonFont,
      titleColor: normalTextColor,
      backgroundColor: normalBackgroundColor
    )
    button.tag = index
    
    // 버튼 스타일 설정
    button.layer.cornerRadius = buttonCornerRadius
    button.layer.borderWidth = buttonBorderWidth
    button.layer.borderColor = normalBorderColor.cgColor
    
    // 버튼 내부 여백 설정
    button.contentEdgeInsets = UIEdgeInsets(
      top: buttonVerticalPadding,
      left: buttonHorizontalPadding,
      bottom: buttonVerticalPadding,
      right: buttonHorizontalPadding
    )
    
    button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
    
    // 버튼 높이 제약조건
    button.snp.makeConstraints { make in
      make.height.equalTo(buttonHeight)
    }
    
    return button
  }
  
  private func createHorizontalStack() -> UIStackView {
    let stackView = UIStackView()
    stackView.axis = .horizontal
    stackView.spacing = horizontalSpacing
    stackView.alignment = .center
    stackView.distribution = .fill
    return stackView
  }
  
  private func updateButtonHeights() {
    for button in buttons {
      button.titleLabel?.font = buttonFont
      button.snp.updateConstraints { make in
        make.height.equalTo(buttonHeight)
      }
    }
  }
}

extension DynamicStackView {
  @objc private func buttonTapped(_ sender: UIButton) {
    let index = sender.tag
    
    if isSingleSelectionMode {
      handleSingleSelection(for: index)
    } else {
      handleMultiSelection(for: index)
    }
    
    // 버튼에 햅틱 피드백 추가
    let generator = UIImpactFeedbackGenerator(style: .light)
    generator.impactOccurred()
  }
  
  private func handleSingleSelection(for index: Int) {
    let currentSelection = selectedIndicesPublisher.value
    
    // 이미 선택된 버튼을 다시 탭했는지 확인
    if currentSelection.contains(index) {
      // 선택 해제
      selectedIndicesPublisher.send([])
      selectionPublisher.send((index: index, title: items[index], isSelected: false))
    } else {
      // 새로운 선택
      selectedIndicesPublisher.send([index])
      selectionPublisher.send((index: index, title: items[index], isSelected: true))
    }
  }
  
  private func handleMultiSelection(for index: Int) {
    var currentSelection = selectedIndicesPublisher.value
    
    // 이미 선택된 버튼을 다시 탭했는지 확인
    if currentSelection.contains(index) {
      // 선택 해제
      currentSelection.remove(index)
      selectionPublisher.send((index: index, title: items[index], isSelected: false))
    } else {
      // 추가 선택
      currentSelection.insert(index)
      selectionPublisher.send((index: index, title: items[index], isSelected: true))
    }
    
    selectedIndicesPublisher.send(currentSelection)
  }
}
