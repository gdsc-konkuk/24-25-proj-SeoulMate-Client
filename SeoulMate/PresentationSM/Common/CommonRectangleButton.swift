//
//  CommonRectangleButton.swift
//  SeoulMate
//
//  Created by 박성근 on 4/7/25.
//

import UIKit

final class CommonRectangleButton: UIButton {
  init(
    title: String = "",
    fontStyle: UIFont,
    titleColor: UIColor = .white,
    backgroundColor: UIColor,
    corners: [UIRectCorner] = [.allCorners],
    radius: CGFloat = 16
  ) {
    super.init(frame: .zero)
    
    setTitle(title, for: .normal)
    titleLabel?.font = fontStyle
    setTitleColor(titleColor, for: .normal)
    self.backgroundColor = backgroundColor
    self.layer.borderColor = UIColor.lightGray.cgColor
    self.layer.borderWidth = 1
    cornerRadius(corners, radius: radius)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
