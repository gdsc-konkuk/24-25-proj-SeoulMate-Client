//
//  PlaceCardView.swift
//  SeoulMate
//
//  Created by 박성근 on 5/4/25.
//

import UIKit
import SnapKit
import Kingfisher
import GooglePlaces

@IBDesignable
final class PlaceCardView: UIView {
  
  @IBOutlet weak var placeImageView: UIImageView!
  @IBOutlet weak var placeName: UILabel!
  @IBOutlet weak var placeAddress: UILabel!
  @IBOutlet weak var placeDistance: UILabel!
  @IBOutlet weak var placeReview: UILabel!
  
  private var placesClient = GMSPlacesClient.shared()
  
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
    
    // 사진 로드
    if let placeId = placeInfo.placeID {
      loadFirstPhoto(from: placeId)
    } else {
      setPlaceholderImage()
    }
  }
  
  private func loadFirstPhoto(from placeID: String) {
    // 기본 이미지 설정
    setPlaceholderImage()
    
    // 장소의 사진 메타데이터 조회
    placesClient.lookUpPhotos(forPlaceID: placeID) { (photos, error) in
      
      // 첫 번째 사진 메타데이터 가져오기
      guard let photoMetadata = photos?.results.first else {
        print("No photos available for this place")
        return
      }
      
      // 사진 요청
      self.placesClient.loadPlacePhoto(photoMetadata) { (photo, error) in
        if let error = error {
          print("Error loading photo: \(error.localizedDescription)")
          self.setPlaceholderImage()
          return
        }
        self.placeImageView?.image = photo
        self.placeImageView?.backgroundColor = .clear
      }
    }
  }
  
  private func setPlaceholderImage() {
    placeImageView?.image = UIImage(systemName: "photo")
    placeImageView?.tintColor = .gray400
    placeImageView?.backgroundColor = .gray200
  }
  
  private func setupUI() {
    layer.cornerRadius = 12
    layer.masksToBounds = true
    
    placeImageView?.layer.cornerRadius = 8
    placeImageView?.clipsToBounds = true
    placeImageView?.contentMode = .scaleAspectFill

    placeName?.numberOfLines = 0
    placeName?.lineBreakMode = .byWordWrapping
    placeName?.adjustsFontSizeToFitWidth = false
    
    placeAddress?.numberOfLines = 0
    placeAddress?.lineBreakMode = .byWordWrapping
    placeAddress?.adjustsFontSizeToFitWidth = false
  }
}
