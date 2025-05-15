//
//  AIChatTypingCell.swift
//  SeoulMate
//
//  Created by 박성근 on 5/12/25.
//

import UIKit
import SnapKit

final class AIChatTypingCell: UITableViewCell {
  // MARK: - Properties
  static let identifier = "AIChatTypingCell"
  
  // UI
  private let profileImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFill
    imageView.layer.cornerRadius = 20
    imageView.clipsToBounds = true
    return imageView
  }()
  
  private let typingBubble: UIView = {
    let view = UIView()
    view.layer.cornerRadius = 16
    view.backgroundColor = .white
    return view
  }()
  
  private let dotStackView: UIStackView = {
    let stack = UIStackView()
    stack.axis = .horizontal
    stack.spacing = 4
    stack.alignment = .center
    return stack
  }()
  
  private var dotViews: [UIView] = []
  
  // MARK: - Initialization
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupUI()
    startTypingAnimation()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Setup
  private func setupUI() {
    selectionStyle = .none
    backgroundColor = .clear
    
    contentView.addSubview(profileImageView)
    profileImageView.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(16)
      make.top.equalToSuperview().offset(4)
      make.width.height.equalTo(40)
    }
    
    contentView.addSubview(typingBubble)
    typingBubble.snp.makeConstraints { make in
      make.top.equalTo(profileImageView.snp.bottom).offset(4)
      make.left.equalTo(profileImageView)
      make.width.equalTo(60)
      make.height.equalTo(40)
      make.bottom.equalToSuperview().offset(-8)
    }
    
    typingBubble.addSubview(dotStackView)
    dotStackView.snp.makeConstraints { make in
      make.center.equalToSuperview()
    }
    
    // Create three dots
    for _ in 0..<3 {
      let dot = UIView()
      dot.backgroundColor = .main500
      dot.layer.cornerRadius = 4
      dot.snp.makeConstraints { make in
        make.width.height.equalTo(8)
      }
      dotViews.append(dot)
      dotStackView.addArrangedSubview(dot)
    }
  }
  
  // MARK: - Animation
  private func startTypingAnimation() {
    for (index, dot) in dotViews.enumerated() {
      dot.alpha = 0.2
      UIView.animate(
        withDuration: 0.6,
        delay: Double(index) * 0.2,
        options: [.repeat, .autoreverse],
        animations: {
          dot.alpha = 1.0
        }
      )
    }
  }
} 
