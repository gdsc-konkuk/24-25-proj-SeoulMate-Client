//
//  DynamicStackView.swift
//  SeoulMate
//
//  Created by 박성근 on 4/7/25.
//

import UIKit

protocol DynamicStackViewDelegate: AnyObject {
  func dynamicStackView(_ stackView: DynamicStackView, didSelectItemAt index: Int, withTitle title: String)
}

final class DynamicStackView: UIStackView {
  
  weak var delegate: DynamicStackViewDelegate?
  
  var verticalSpacing: CGFloat = 16
  var horizontalSpacing: CGFloat = 10
  var maxWidth: CGFloat = UIApplication.screenWidth - 40
  
  private var buttons: [CommonRectangleButton] = []
  private var items: [String] = []
  private var horizontalStacks: [UIStackView] = []
  
  private var selectedIndex: Int?
  
  var normalBackgroundColor: UIColor = .white
  var selectedBackgroundColor: UIColor = .black
  var normalTextColor: UIColor = .lightGray
  var selectedTextColor: UIColor = .white
  
  // MARK: - LifeCycle
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupStackView()
  }
  
  required init(coder: NSCoder) {
    super.init(coder: coder)
    setupStackView()
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
  
  func getSelectedIndex() -> Int? {
    return selectedIndex
  }
  
  func getSelectedTitle() -> String? {
    if let index = selectedIndex, index < items.count {
      return items[index]
    }
    return nil
  }
  
  func selectItem(at index: Int) {
    guard index < buttons.count else { return }
    buttonTapped(buttons[index])
  }
  
  func clearSelection() {
    selectedIndex = nil
    
    for button in buttons {
      button.backgroundColor = normalBackgroundColor
      button.setTitleColor(normalTextColor, for: .normal)
    }
  }
}

extension DynamicStackView {
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
    
    // 버튼에 패딩 추가
    button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 18, bottom: 10, right: 18)
    
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
  @objc private func buttonTapped(_ sender: UIButton) {
    let index = sender.tag
    
    if let selectedIndex = selectedIndex, selectedIndex != index {
      // 이전에 선택된 버튼 초기화
      if selectedIndex < buttons.count {
        let previousButton = buttons[selectedIndex]
        previousButton.backgroundColor = normalBackgroundColor
        previousButton.setTitleColor(normalTextColor, for: .normal)
      }
    }
    
    // 현재 버튼이 이미 선택되어 있는지 확인
    if selectedIndex == index {
      // 선택 해제
      sender.backgroundColor = normalBackgroundColor
      sender.setTitleColor(normalTextColor, for: .normal)
      self.selectedIndex = nil
    } else {
      // 선택
      sender.backgroundColor = selectedBackgroundColor
      sender.setTitleColor(selectedTextColor, for: .normal)
      self.selectedIndex = index
      
      // 델리게이트 호출
      if index < items.count {
        delegate?.dynamicStackView(self, didSelectItemAt: index, withTitle: items[index])
      }
    }
  }
}
