//
//  UserMessageCell.swift
//  SeoulMate
//
//  Created by 박성근 on 3/27/25.
//

import UIKit
import SnapKit
import CoreData

class UserMessageCell: BaseMessageCell {
  static let identifier = "UserMessageCell"
  
  override func setupUI() {
    super.setupUI()
    messageBubble.backgroundColor = .systemBlue
    messageLabel.textColor = .white
  }
  
  func configure(with message: ChatMessage) {
    configureMessage(text: message.text ?? "", date: message.timestamp ?? Date())

    // Layout: [timestamp][bubble] right-aligned
    messageBubble.snp.remakeConstraints { make in
      make.top.greaterThanOrEqualToSuperview().offset(8)
      make.bottom.equalToSuperview().offset(-8)
      make.trailing.equalToSuperview().offset(-16)
      make.leading.greaterThanOrEqualToSuperview().offset(60)
    }
    timestampLabel.snp.remakeConstraints { make in
      make.trailing.equalTo(messageBubble.snp.leading).offset(-8)
      make.top.equalTo(messageBubble.snp.top).offset(20)
    }
    
    // Store corners for layoutSubviews
    bubbleCorners = ([.topLeft, .bottomLeft, .bottomRight], 16)
    setNeedsLayout()
  }
} 
