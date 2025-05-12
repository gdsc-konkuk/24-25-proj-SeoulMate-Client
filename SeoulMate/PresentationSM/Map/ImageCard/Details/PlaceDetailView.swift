//
//  PlaceDetailView.swift
//  SeoulMate
//
//  Created by 박성근 on 5/5/25.
//

import UIKit
import SnapKit
import GooglePlaces

protocol PlaceDetailViewDelegate: AnyObject {
  func didTapAskToBotButton(with placeInfo: PlaceCardInfo)
  func didTapDismissButton(reason: DismissReason)
}

enum DismissReason {
  case askToBot
  case backgroundTap
}

final class PlaceDetailView: UIView {
  // MARK: - Properties
  weak var delegate: PlaceDetailViewDelegate?
  private var placeInfo: PlaceCardInfo?
  private var placesClient = GMSPlacesClient.shared()
  private var photos: [UIImage] = []
  private var currentIndex: Int = 0
  
  // MARK: - UI Components
  private let imageCarousel: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.minimumLineSpacing = 0
    layout.sectionInset = .zero
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.isPagingEnabled = true
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.backgroundColor = .clear
    collectionView.layer.cornerRadius = 16
    collectionView.clipsToBounds = true
    return collectionView
  }()
  
  private let loadingIndicator: UIActivityIndicatorView = {
    let indicator = UIActivityIndicatorView(style: .medium)
    indicator.hidesWhenStopped = true
    indicator.color = .white
    return indicator
  }()
  
  private let pageControl = UIPageControl()
  
  let likeButton: UIButton = {
    let button = UIButton(type: .custom)
    button.setImage(UIImage(systemName: "heart"), for: .normal)
    button.setImage(UIImage(systemName: "heart.fill"), for: .selected)
    button.tintColor = .white
    button.backgroundColor = UIColor.black.withAlphaComponent(0.3)
    button.layer.cornerRadius = 18
    button.clipsToBounds = true
    return button
  }()
  
  private let tagStackView = DynamicStackView()
  
  private let nameLabel = UILabel()
  
  private let addressLabel = ScrollableLabel()
  
  private let infoLabel = UILabel() // 거리/별점/리뷰수
  
  private let descriptionTextView: UITextView = {
    let tv = UITextView()
    tv.isEditable = false
    tv.isScrollEnabled = true
    tv.showsVerticalScrollIndicator = true
    tv.font = .regularFont(ofSize: 16)
    tv.textColor = .black
    tv.backgroundColor = .clear
    tv.textContainerInset = .zero
    tv.textContainer.lineFragmentPadding = 0
    tv.isScrollEnabled = true
    return tv
  }()
  
  private let askToBotButton = CommonRectangleButton(
    title: "Ask to Bot",
    fontStyle: .boldFont(ofSize: 18),
    titleColor: .white,
    backgroundColor: .main500,
    radius: 24
  )
  
  // MARK: - Init
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupUI()
  }
  
  // MARK: - Setup
  private func setupUI() {
    backgroundColor = .white
    layer.cornerRadius = 20
    layer.masksToBounds = true
    
    addSubview(imageCarousel)
    addSubview(loadingIndicator)
    addSubview(likeButton)
    addSubview(pageControl)
    addSubview(tagStackView)
    addSubview(nameLabel)
    addSubview(addressLabel)
    addSubview(infoLabel)
    addSubview(askToBotButton)
    addSubview(descriptionTextView)
    
    // 1. 이미지 캐러셀
    imageCarousel.delegate = self
    imageCarousel.dataSource = self
    imageCarousel.register(ImageCarouselCell.self, forCellWithReuseIdentifier: ImageCarouselCell.identifier)
    imageCarousel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(16)
      make.left.equalToSuperview().offset(16)
      make.right.equalToSuperview().offset(-16)
      make.height.equalTo(198)
    }
    
    // 로딩 인디케이터 추가
    loadingIndicator.snp.makeConstraints { make in
      make.center.equalTo(imageCarousel)
    }
    
    // 2. 좋아요 버튼
    likeButton.snp.makeConstraints { make in
      make.top.equalTo(imageCarousel).offset(12)
      make.right.equalTo(imageCarousel).offset(-12)
      make.width.height.equalTo(36)
    }
    
    // 3. 페이지 컨트롤
    pageControl.snp.makeConstraints { make in
      make.centerX.equalTo(imageCarousel)
      make.bottom.equalTo(imageCarousel).offset(-8)
    }
    
    // 4. 태그 스택뷰
    tagStackView.normalBackgroundColor = .main100
    tagStackView.normalTextColor = .main500
    tagStackView.buttonFont = .mediumFont(ofSize: 12)
    tagStackView.buttonVerticalPadding = 4
    tagStackView.buttonHorizontalPadding = 8
    tagStackView.horizontalSpacing = 8
    tagStackView.verticalSpacing = 8
    tagStackView.buttonCornerRadius = 10
    tagStackView.snp.makeConstraints { make in
      make.top.equalTo(imageCarousel.snp.bottom).offset(10)
      make.left.equalToSuperview().offset(16)
      make.height.equalTo(40)
    }
    
    // 5. 장소명
    nameLabel.font = .boldFont(ofSize: 20)
    nameLabel.snp.makeConstraints { make in
      make.top.equalTo(tagStackView.snp.bottom).offset(8)
      make.left.equalToSuperview().offset(16)
    }
    
    // 6. 주소
    addressLabel.snp.makeConstraints { make in
      make.top.equalTo(nameLabel.snp.bottom).offset(4)
      make.left.equalToSuperview().offset(16)
      make.right.equalToSuperview().offset(-16)
      make.height.equalTo(20)
    }
    
    // 7. 거리/별점/리뷰수
    infoLabel.font = .mediumFont(ofSize: 14)
    infoLabel.snp.makeConstraints { make in
      make.top.equalTo(addressLabel.snp.bottom).offset(4)
      make.left.equalToSuperview().offset(16)
    }
    
    // 8. 설명
    descriptionTextView.snp.makeConstraints { make in
      make.top.equalTo(infoLabel.snp.bottom).offset(19)
      make.left.equalToSuperview().offset(16)
      make.right.equalToSuperview().offset(-16)
      make.height.greaterThanOrEqualTo(100)
      make.bottom.lessThanOrEqualTo(askToBotButton.snp.top).offset(-20)
    }
    
    // 9. Ask to Bot 버튼
    askToBotButton.addTarget(self, action: #selector(handleAskToBotButtonTap), for: .touchUpInside)
    askToBotButton.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(24)
      make.right.equalToSuperview().offset(-24)
      make.height.equalTo(44)
      make.bottom.equalToSuperview().offset(-24)
    }
  }
  
  // MARK: - Actions
  @objc private func handleAskToBotButtonTap() {
    guard let placeInfo = placeInfo else { return }
    delegate?.didTapAskToBotButton(with: placeInfo)
  }
  
  @objc private func handleDismissButtonTap() {
    delegate?.didTapDismissButton(reason: .backgroundTap)
  }
  
  // MARK: - Configuration
  func configure(with placeInfo: PlaceCardInfo, purposes: [String]) {
    self.placeInfo = placeInfo
    nameLabel.text = placeInfo.name
    addressLabel.setText(placeInfo.address)
    addressLabel.setFont(.regularFont(ofSize: 14))
    addressLabel.setTextColor(.gray)
    setInfoLabel(distanceText: placeInfo.distanceText, ratingText: placeInfo.ratingText)
    descriptionTextView.text = placeInfo.description ?? "No description available"
    
    tagStackView.setItems(purposes)
    for button in tagStackView.buttons {
      button.snp.remakeConstraints { make in
        make.height.equalTo(22)
      }
    }
    tagStackView.isUserInteractionEnabled = false
    
    // 사진 로드
    if let placeId = placeInfo.placeID {
      loadPhotos(from: placeId)
    } else {
      setPlaceholderImage()
    }
  }
  
  private func loadPhotos(from placeID: String) {
    // 기존 이미지 초기화
    photos.removeAll()
    imageCarousel.reloadData()
    
    // 로딩 인디케이터 시작
    loadingIndicator.startAnimating()
    
    // 장소의 사진 메타데이터 조회
    placesClient.lookUpPhotos(forPlaceID: placeID) { [weak self] (photos, error) in
      guard let self = self else { return }
      
      if let error = error {
        print("Error fetching photos: \(error.localizedDescription)")
        self.setPlaceholderImage()
        self.loadingIndicator.stopAnimating()
        return
      }
      
      // 최대 3개의 사진 메타데이터 가져오기
      let photoMetadataList = photos?.results.prefix(3) ?? []
      
      if photoMetadataList.isEmpty {
        print("No photos available for this place")
        self.setPlaceholderImage()
        self.loadingIndicator.stopAnimating()
        return
      }
      
      // 페이지 컨트롤 설정
      self.pageControl.numberOfPages = photoMetadataList.count
      self.pageControl.currentPage = 0
      
      // 각 사진 로드
      let group = DispatchGroup()
      
      for photoMetadata in photoMetadataList {
        group.enter()
        
        self.placesClient.loadPlacePhoto(photoMetadata) { [weak self] (photo, error) in
          defer { group.leave() }
          
          guard let self = self else { return }
          
          if let error = error {
            print("Error loading photo: \(error.localizedDescription)")
            return
          }
          
          if let photo = photo {
            DispatchQueue.main.async {
              self.photos.append(photo)
            }
          }
        }
      }
      
      group.notify(queue: .main) { [weak self] in
        guard let self = self else { return }
        
        self.loadingIndicator.stopAnimating()
        
        if self.photos.isEmpty {
          self.setPlaceholderImage()
        } else {
          self.imageCarousel.reloadData()
        }
      }
    }
  }
  
  private func setPlaceholderImage() {
    photos = [UIImage(systemName: "photo")!]
    pageControl.numberOfPages = 1
    pageControl.currentPage = 0
    imageCarousel.reloadData()
  }
  
  func setInfoLabel(distanceText: String, ratingText: String) {
    let infoString = NSMutableAttributedString()
    
    // 1. plain 이미지
    if let plainImage = UIImage(named: "plain") {
      let plainAttachment = NSTextAttachment()
      plainAttachment.image = plainImage
      plainAttachment.bounds = CGRect(x: 0, y: 0, width: 10, height: 10)
      infoString.append(NSAttributedString(attachment: plainAttachment))
      infoString.append(NSAttributedString(string: "  ")) // 이미지와 텍스트 사이 간격
    }
    
    // 2. 거리 텍스트
    infoString.append(NSAttributedString(string: distanceText + "  "))
    
    // 3. star 이미지
    if let starImage = UIImage(named: "star") {
      let starAttachment = NSTextAttachment()
      starAttachment.image = starImage
      starAttachment.bounds = CGRect(x: 0, y: 0, width: 10, height: 10)
      infoString.append(NSAttributedString(attachment: starAttachment))
      infoString.append(NSAttributedString(string: "  ")) // 이미지와 텍스트 사이 간격
    }
    
    // 4. 평점 텍스트
    infoString.append(NSAttributedString(string: ratingText))
    
    infoLabel.attributedText = infoString
  }
}

// MARK: - UICollectionViewDataSource
extension PlaceDetailView: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return photos.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCarouselCell.identifier, for: indexPath) as? ImageCarouselCell else {
      return UICollectionViewCell()
    }
    
    cell.configure(with: photos[indexPath.item])
    return cell
  }
}

// MARK: - UICollectionViewDelegate
extension PlaceDetailView: UICollectionViewDelegate {
  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    let pageWidth = scrollView.frame.width
    currentIndex = Int(scrollView.contentOffset.x / pageWidth)
    pageControl.currentPage = currentIndex
  }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension PlaceDetailView: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return collectionView.bounds.size
  }
}
