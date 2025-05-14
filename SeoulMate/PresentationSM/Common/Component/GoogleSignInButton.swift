//
//  GoogleSignInButton.swift
//  SeoulMate
//
//  Created by 박성근 on 5/10/25.
//

import UIKit
import SnapKit

final class GoogleSignInButton: UIButton {
  private let logoImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFit
    imageView.clipsToBounds = true
    return imageView
  }()
  
  private let titleLabelCustom: UILabel = {
    let label = UILabel()
    label.font = .mediumFont(ofSize: 16)
    label.textColor = .black
    label.textAlignment = .center
    return label
  }()
  
  init() {
    super.init(frame: .zero)
    setupUI()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setupUI() {
    self.backgroundColor = .white
    self.layer.cornerRadius = 28 // pill style for height 56
    self.layer.borderWidth = 1
    self.layer.borderColor = UIColor.gray200.cgColor
    self.clipsToBounds = true
    
    logoImageView.image = UIImage(named: "googleLogo")
    addSubview(logoImageView)
    addSubview(titleLabelCustom)
    
    titleLabelCustom.text = "Continue with Google"
    
    self.snp.makeConstraints { make in
      make.height.equalTo(56)
    }
    
    logoImageView.snp.makeConstraints { make in
      make.leading.equalToSuperview().offset(20)
      make.centerY.equalToSuperview()
      make.width.height.equalTo(20)
    }
    
    titleLabelCustom.snp.makeConstraints { make in
      make.center.equalToSuperview()
    }
  }
}
