//
//  BotMessageCell.swift
//  SeoulMate
//
//  Created by 박성근 on 3/27/25.
//

import UIKit
import SnapKit
import Combine

protocol BotMessageCellDelegate: AnyObject {
  func didTapFitnessScore()
  func didTapFreeChat()
}

final class BotMessageCell: BaseMessageCell {
  static let identifier = "BotMessageCell"
  
  weak var delegate: BotMessageCellDelegate?
  
  private var subscriptions = Set<AnyCancellable>()
  
  private let profileImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFill
    imageView.layer.cornerRadius = 20
    imageView.clipsToBounds = true
    imageView.backgroundColor = .systemGray5
    return imageView
  }()
  
  private let chatTypeStackView: DynamicStackView = {
    let stackView = DynamicStackView()
    stackView.isSingleSelectionMode = true
    stackView.buttonFont = .mediumFont(ofSize: 16)
    stackView.buttonHeight = 40
    stackView.buttonCornerRadius = 20
    stackView.buttonVerticalPadding = 10
    stackView.buttonHorizontalPadding = 18
    return stackView
  }()
  
  override func setupUI() {
    super.setupUI()
    contentView.addSubview(profileImageView)
    contentView.addSubview(chatTypeStackView)
    messageBubble.backgroundColor = .systemGray6
    messageLabel.textColor = .black
    
    // Set the items after adding to contentView
    chatTypeStackView.setItems(["Fitness Score", "Free Chat"])
    
    // 기존 레이아웃
    profileImageView.snp.remakeConstraints { make in
      make.left.equalToSuperview().offset(16)
      make.top.equalToSuperview().offset(4)
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
    
    // 셀렉션 퍼블리셔 구독
    chatTypeStackView.selectionPublisher
      .sink { [weak self] selectedItem in
        guard let self = self else { return }
        
        if selectedItem.isSelected {
          if selectedItem.index == 0 { // Fitness Score
            self.delegate?.didTapFitnessScore()
          } else if selectedItem.index == 1 { // Free Chat
            self.delegate?.didTapFreeChat()
          }
          
          // 선택 해제
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.chatTypeStackView.clearSelection()
          }
        }
      }
      .store(in: &subscriptions)
  }
  
  func configure(with message: ChatMessage) {
    configureMessage(text: message.text, date: message.timestamp)
    
    // 첫 번째 셀의 상단 여백 조정
    profileImageView.snp.updateConstraints { make in
      make.top.equalToSuperview().offset(0) // 상단 여백 제거
    }
    
    bubbleCorners = ([.topRight, .bottomLeft, .bottomRight], 16)
    setNeedsLayout()
  }
}
