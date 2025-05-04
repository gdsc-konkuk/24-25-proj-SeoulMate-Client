//
//  PlaceCardView.swift
//  SeoulMate
//
//  Created by 박성근 on 5/4/25.
//

import UIKit
import SnapKit

@IBDesignable
final class PlaceCardView: UIView {
  
  @IBOutlet weak var placeImageView: UIImageView!
  
  @IBOutlet weak var placeName: UILabel!
  @IBOutlet weak var placeAddress: UILabel!
  @IBOutlet weak var placeDistance: UILabel!
  @IBOutlet weak var placeReview: UILabel!
  
  // MARK: - Initializers
  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }
  
  // MARK: - Setup from XIB
  private func commonInit() {
    guard let view = loadViewFromNib() else { return }
    view.frame = self.bounds
    self.addSubview(view)
    
    setupUI()
  }
  
  private func loadViewFromNib() -> UIView? {
    let bundle = Bundle(for: type(of: self))
    let nib = UINib(nibName: "PlaceCardView", bundle: bundle)
    return nib.instantiate(withOwner: self, options: nil).first as? UIView
  }
  
  // MARK: - Configuration
  func configure(with placeInfo: PlaceCardInfo) {
    placeName?.text = placeInfo.name
    placeAddress?.text = placeInfo.address
    placeDistance?.text = placeInfo.distanceText
    placeReview?.text = placeInfo.ratingText
    
    // 이미지 설정
    if let imageUrl = placeInfo.imageUrl,
       let url = URL(string: imageUrl) {
      // TODO: 실제 이미지 로딩 구현
      placeImageView?.backgroundColor = .gray200
    } else {
      placeImageView?.image = UIImage(systemName: "photo")
      placeImageView?.tintColor = .gray400
      placeImageView?.backgroundColor = .gray200
    }
  }
  
  private func setupUI() {
    layer.cornerRadius = 12
    layer.masksToBounds = true
    
    placeImageView?.layer.cornerRadius = 8
    placeImageView?.clipsToBounds = true
    placeImageView?.contentMode = .scaleAspectFill
  }
}
