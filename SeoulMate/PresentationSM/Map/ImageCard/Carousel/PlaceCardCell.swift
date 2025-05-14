//
//  PlaceCardCell.swift
//  SeoulMate
//
//  Created by 박성근 on 5/4/25.
//

import UIKit
import SnapKit

final class PlaceCardCell: UICollectionViewCell {
  static let identifier = "PlaceCardCell"
  
  private var cardView: PlaceCardView!
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setupUI() {
    cardView = PlaceCardView(frame: contentView.bounds)
    contentView.addSubview(cardView)
    
    cardView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }
  
  func configure(with place: PlaceCardInfo) {
    Logger.log("PlaceCardCell - 카드 구성: \(place.name)")
    cardView.configure(with: place)
  }
}
