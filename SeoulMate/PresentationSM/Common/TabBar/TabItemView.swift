//
//  TabBarItemView.swift
//  SeoulMate
//
//  Created by 박성근 on 5/3/25.
//

import UIKit
import SnapKit

final class TabItemView: UIView {
  private let iconImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFit
    imageView.tintColor = .gray400
    return imageView
  }()
  
  private let titleLabel: UILabel = {
    let label = UILabel()
    label.font = .boldFont(ofSize: 12)
    label.textColor = .gray400
    label.textAlignment = .center
    return label
  }()
  
  private let baseIconName: String
  
  var isSelected: Bool = false {
    didSet {
      updateSelectionState()
    }
  }
  
  init(icon: String, title: String) {
    self.baseIconName = icon
    super.init(frame: .zero)
    setupUI()
    iconImageView.image = UIImage(named: icon)
    titleLabel.text = title
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override var intrinsicContentSize: CGSize {
    let labelSize = titleLabel.intrinsicContentSize
    let width = max(44, labelSize.width + 16)
    return CGSize(width: width, height: 50)
  }
  
  private func setupUI() {
    addSubview(iconImageView)
    addSubview(titleLabel)
    
    iconImageView.snp.makeConstraints { make in
      make.top.centerX.equalToSuperview()
      make.width.height.equalTo(24)
    }
    
    titleLabel.snp.makeConstraints { make in
      make.top.equalTo(iconImageView.snp.bottom).offset(6)
      make.centerX.equalToSuperview()
      make.leading.greaterThanOrEqualToSuperview().offset(8)
      make.trailing.lessThanOrEqualToSuperview().offset(-8)
      make.bottom.equalToSuperview()
    }
  }
  
  private func updateSelectionState() {
    let imageName = isSelected ? "\(baseIconName)Selected" : "\(baseIconName)NotSelected"
    iconImageView.image = UIImage(named: imageName)
    
    titleLabel.textColor = isSelected ? .gray900 : .gray400
  }
}
