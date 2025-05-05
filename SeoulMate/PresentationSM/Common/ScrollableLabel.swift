//
//  ScrollableLabel.swift
//  SeoulMate
//
//  Created by 박성근 on 5/5/25.
//

import UIKit

final class ScrollableLabel: UIView {
  private let scrollView = UIScrollView()
  private let label = UILabel()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupUI()
  }
  
  private func setupUI() {
    addSubview(scrollView)
    scrollView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.alwaysBounceHorizontal = true
    scrollView.bounces = true
    
    scrollView.addSubview(label)
    label.snp.makeConstraints { make in
      make.top.bottom.equalToSuperview()
      make.left.right.equalToSuperview()
      make.height.equalToSuperview() // 한 줄만
    }
    label.lineBreakMode = .byClipping
    label.numberOfLines = 1
  }
  
  func setText(_ text: String) {
    label.text = text
    label.sizeToFit()
    scrollView.contentSize = CGSize(width: label.frame.width, height: scrollView.frame.height)
  }
  
  func setFont(_ font: UIFont) {
    label.font = font
  }
  func setTextColor(_ color: UIColor) {
    label.textColor = color
  }
}
