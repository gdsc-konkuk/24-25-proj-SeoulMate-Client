//
//  ImageCarouselCell.swift
//  SeoulMate
//
//  Created by 박성근 on 5/5/25.
//

import UIKit
import SnapKit

final class ImageCarouselCell: UICollectionViewCell {
  static let identifier = "ImageCarouselCell"
  
  private let imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    imageView.backgroundColor = .gray200
    imageView.layer.cornerRadius = 16
    return imageView
  }()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setupUI() {
    contentView.addSubview(imageView)
    imageView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }
  
  func configure(with image: UIImage) {
    imageView.image = image
  }
} 