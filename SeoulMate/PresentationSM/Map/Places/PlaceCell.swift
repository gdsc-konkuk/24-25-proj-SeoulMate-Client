//
//  PlaceCell.swift
//  SeoulMate
//
//  Created by 박성근 on 4/8/25.
//

import UIKit
import SnapKit

final class PlaceCell: UITableViewCell {
  
  static let identifier = "PlaceCell"
  
  // MARK: - UI Properties
  private let iconBackgroundView: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor.lightGray.withAlphaComponent(0.2)
    view.layer.cornerRadius = 25
    return view
  }()
  
  private let iconImageView: UIImageView = {
    let imageView = UIImageView()
    let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
    let pinImage = UIImage(systemName: "mappin", withConfiguration: config)
    imageView.image = pinImage
    imageView.tintColor = .black
    imageView.contentMode = .scaleAspectFit
    return imageView
  }()
  
  private let placeNameLabel: UILabel = {
    let label = UILabel()
    label.font = .mediumFont(ofSize: 16)
    label.textColor = .black
    label.numberOfLines = 1
    return label
  }()
  
  private let arrowImageView: UIImageView = {
    let imageView = UIImageView()
    let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
    let arrowImage = UIImage(systemName: "arrow.up.right", withConfiguration: config)
    imageView.image = arrowImage
    imageView.tintColor = .darkGray
    imageView.contentMode = .scaleAspectFit
    return imageView
  }()
  
  // MARK: - Initialization
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupUI()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setupUI() {
    backgroundColor = .white
    
    // addSubview
    contentView.addSubview(iconBackgroundView)
    iconBackgroundView.addSubview(iconImageView)
    contentView.addSubview(placeNameLabel)
    contentView.addSubview(arrowImageView)
    
    iconBackgroundView.snp.makeConstraints { make in
      make.leading.equalToSuperview().offset(12)
      make.centerY.equalToSuperview()
      make.width.height.equalTo(32) // 아이콘 배경 크기 축소
    }
    
    iconImageView.snp.makeConstraints { make in
      make.center.equalTo(iconBackgroundView)
      make.width.height.equalTo(16) // 아이콘 크기 축소
    }
    
    placeNameLabel.snp.makeConstraints { make in
      make.leading.equalTo(iconBackgroundView.snp.trailing).offset(10) // 여백 축소
      make.centerY.equalToSuperview()
      make.trailing.lessThanOrEqualTo(arrowImageView.snp.leading).offset(-8) // 여백 축소
    }
    
    arrowImageView.snp.makeConstraints { make in
      make.trailing.equalToSuperview().offset(-12) // 여백 축소
      make.centerY.equalToSuperview()
      make.width.height.equalTo(20) // 화살표 크기 축소
    }
  }
  
  // MARK: - Configuration
  func configure(with title: String) {
    placeNameLabel.text = title
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    placeNameLabel.text = nil
  }
}
