//
//  BaseMessageCell.swift
//  SeoulMate
//
//  Created by 박성근 on 3/27/25.
//

import UIKit
import SnapKit

class BaseMessageCell: UITableViewCell {
  let messageBubble = UIView()
  let messageLabel = UILabel()
  let timestampLabel = UILabel()
  var bubbleCorners: ([UIRectCorner], CGFloat) = ([.allCorners], 16)
  
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupUI()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    messageBubble.cornerRadius(bubbleCorners.0, radius: bubbleCorners.1)
  }
  
  func setupUI() {
    selectionStyle = .none
    backgroundColor = .clear
    contentView.addSubview(messageBubble)
    messageBubble.addSubview(messageLabel)
    contentView.addSubview(timestampLabel)
    messageLabel.font = .mediumFont(ofSize: 16)
    messageLabel.numberOfLines = 0
    timestampLabel.font = .regularFont(ofSize: 12)
    timestampLabel.textColor = .gray500
    messageLabel.snp.makeConstraints { make in
      make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12))
    }
  }
  
  func configureMessage(text: String, date: Date) {
    messageLabel.text = text
    timestampLabel.text = formatTimestamp(date)
  }
  
  private func formatTimestamp(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter.string(from: date)
  }
}
