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
  
  private let chatTypeStackView: DynamicStackView = {
    let stack = DynamicStackView()
    stack.setItems(["Fitness Score", "Free Chat"])
    stack.buttonHeight = 40
    stack.buttonFont = .mediumFont(ofSize: 16)
    stack.normalBackgroundColor = .white
    stack.normalTextColor = .gray500
    stack.normalBorderColor = .gray500
    stack.selectedBackgroundColor = .main100
    stack.selectedTextColor = .main500
    stack.selectedBorderColor = .main500
    stack.buttonCornerRadius = 20
    return stack
  }()
  
  override func setupUI() {
    super.setupUI()
    contentView.addSubview(profileImageView)
    contentView.addSubview(chatTypeStackView)
    messageBubble.backgroundColor = .systemGray6
    messageLabel.textColor = .black
    
    // 기존 레이아웃
    profileImageView.snp.remakeConstraints { make in
      make.left.equalToSuperview().offset(16)
      make.top.equalToSuperview().offset(8)
      make.width.height.equalTo(40)
    }
    
    // messageBubble은 profileImageView 아래
    messageBubble.snp.remakeConstraints { make in
      make.top.equalTo(profileImageView.snp.bottom).offset(4)
      make.left.equalTo(profileImageView)
      make.right.lessThanOrEqualToSuperview().offset(-60)
    }
    
    // chatTypeStackView는 messageBubble 아래
    chatTypeStackView.snp.makeConstraints { make in
      make.top.equalTo(messageBubble.snp.bottom).offset(8)
      make.left.right.equalToSuperview().inset(16)
      make.height.equalTo(56)
      make.bottom.lessThanOrEqualToSuperview().offset(-8)
    }
    
    timestampLabel.snp.remakeConstraints { make in
      make.left.equalTo(profileImageView.snp.right).offset(8)
      make.top.equalTo(profileImageView.snp.top).offset(24)
    }
  }
  
  func configure(with message: ChatMessage, showChatTypeStackView: Bool = false) {
    configureMessage(text: message.text, date: message.timestamp)
    
    bubbleCorners = ([.topRight, .bottomLeft, .bottomRight], 16)
    setNeedsLayout()
  }
}
