//
//  BotMessageCell.swift
//  SeoulMate
//
//  Created by 박성근 on 3/27/25.
//

import UIKit
import SnapKit
import CoreData

class BotMessageCell: BaseMessageCell {
  static let identifier = "BotMessageCell"
  private let profileImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFill
    imageView.layer.cornerRadius = 20
    imageView.clipsToBounds = true
    imageView.backgroundColor = .systemGray5
    return imageView
  }()
  
  override func setupUI() {
    super.setupUI()
    contentView.addSubview(profileImageView)
    messageBubble.backgroundColor = .systemGray6
    messageLabel.textColor = .black
  }
  
  func configure(with message: ChatMessage) {
    configureMessage(text: message.text ?? "", date: message.timestamp ?? Date())
    // Layout: [profile][timestamp] (top), [profile][bubble] (bottom)
    profileImageView.snp.remakeConstraints { make in
      make.left.equalToSuperview().offset(16)
      make.top.equalToSuperview().offset(8)
      make.width.height.equalTo(40)
    }
    timestampLabel.snp.remakeConstraints { make in
      make.left.equalTo(profileImageView.snp.right).offset(8)
      make.top.equalTo(profileImageView.snp.top).offset(24)
    }
    messageBubble.snp.remakeConstraints { make in
      make.top.equalTo(profileImageView.snp.bottom).offset(4)
      make.left.equalTo(profileImageView)
      make.right.lessThanOrEqualToSuperview().offset(-60)
      make.bottom.equalToSuperview().offset(-8)
    }
    // Store corners for layoutSubviews
    bubbleCorners = ([.topRight, .bottomLeft, .bottomRight], 16)
    setNeedsLayout()
  }
}
