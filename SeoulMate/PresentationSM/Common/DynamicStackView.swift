//
//  DynamicStackView.swift
//  SeoulMate
//
//  Created by 박성근 on 4/7/25.
//

import UIKit
import Combine

final class DynamicStackView: UIStackView {
  
  // MARK: - Publisher
  let selectionPublisher = PassthroughSubject<(index: Int, title: String, isSelected: Bool), Never>()
  let selectedIndicesPublisher =  CurrentValueSubject<Set<Int>, Never>(Set<Int>())
  
  var verticalSpacing: CGFloat = 16
  var horizontalSpacing: CGFloat = 10
  var maxWidth: CGFloat = UIApplication.screenWidth - 40
  
  private var buttons: [CommonRectangleButton] = []
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
  var selectedBackgroundColor: UIColor = .black
  var normalTextColor: UIColor = .lightGray
  var selectedTextColor: UIColor = .white
  
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
          } else {
            button.backgroundColor = self.normalBackgroundColor
            button.setTitleColor(self.normalTextColor, for: .normal)
          }
        }
      }
      .store(in: &subscriptions)
  }
  
  private func setupStackView() {
    self.axis = .vertical
    alignment = .leading
    spacing = verticalSpacing
    distribution = .fillProportionally
  }
  
  private func createButton(withTitle title: String, at index: Int) -> CommonRectangleButton {
    let button = CommonRectangleButton(
      title: title,
      fontStyle: .mediumFont(ofSize: 18),
      titleColor: normalTextColor,
      backgroundColor: normalBackgroundColor
    )
    button.tag = index
    button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
    
    button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 18, bottom: 10, right: 18)
    button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
    button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    
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
}

extension DynamicStackView {
  // 버튼 터치 시작 시 시각적 피드백
  @objc private func buttonTouchDown(_ sender: UIButton) {
    UIView.animate(withDuration: 0.1) {
      sender.layer.borderColor = UIColor.cyan.cgColor
      sender.layer.borderWidth = 2
    }
  }
  
  // 버튼 터치 종료 시 원래 상태로 복귀
  @objc private func buttonTouchUp(_ sender: UIButton) {
    UIView.animate(withDuration: 0.1) {
      sender.layer.borderColor = UIColor.lightGray.cgColor
      sender.layer.borderWidth = 1
    }
  }
  
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
