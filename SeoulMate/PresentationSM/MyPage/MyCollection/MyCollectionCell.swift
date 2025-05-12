import UIKit
import SnapKit

final class MyCollectionCell: UICollectionViewCell {
  // MARK: - Properties
  static let identifier = "MyCollectionCell"
  private var photos: [UIImage] = []
  
  // MARK: - UI Components
  private let imageCarousel: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.minimumLineSpacing = 8
    layout.sectionInset = .zero
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.isPagingEnabled = false // 페이징 비활성화
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.backgroundColor = .clear
    collectionView.layer.cornerRadius = 16
    collectionView.clipsToBounds = true
    return collectionView
  }()
  
  private let nameLabel: UILabel = {
    let label = UILabel()
    label.font = .boldFont(ofSize: 20)
    return label
  }()
  
  private let addressLabel: ScrollableLabel = {
    let label = ScrollableLabel()
    label.setFont(.regularFont(ofSize: 14))
    label.setTextColor(.gray)
    return label
  }()
  
  private let infoLabel: UILabel = {
    let label = UILabel()
    label.font = .mediumFont(ofSize: 14)
    return label
  }()
  
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
    backgroundColor = .gray50
    layer.cornerRadius = 0
    layer.masksToBounds = true
    
    // 1. 이미지 캐러셀
    imageCarousel.delegate = self
    imageCarousel.dataSource = self
    imageCarousel.register(ImageCarouselCell.self, forCellWithReuseIdentifier: ImageCarouselCell.identifier)
    contentView.addSubview(imageCarousel)
    imageCarousel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(16)
      make.left.equalToSuperview().offset(16)
      make.right.equalToSuperview().offset(-16)
      make.height.equalTo(135)
    }
    
    // 3. 장소명
    nameLabel.font = .boldFont(ofSize: 20)
    contentView.addSubview(nameLabel)
    nameLabel.snp.makeConstraints { make in
      make.top.equalTo(imageCarousel.snp.bottom).offset(12)
      make.left.equalToSuperview().offset(16)
    }
    
    // 4. 주소
    contentView.addSubview(addressLabel)
    addressLabel.snp.makeConstraints { make in
      make.top.equalTo(nameLabel.snp.bottom).offset(4)
      make.left.equalToSuperview().offset(16)
      make.right.equalToSuperview().offset(-16)
      make.height.equalTo(20)
    }
    
    // 5. 거리/별점/리뷰수
    infoLabel.font = .mediumFont(ofSize: 14)
    contentView.addSubview(infoLabel)
    infoLabel.snp.makeConstraints { make in
      make.top.equalTo(addressLabel.snp.bottom).offset(12)
      make.left.equalToSuperview().offset(16)
      make.bottom.equalToSuperview().offset(-16)
    }
  }
  
  // MARK: - Configuration
  func configure(with placeInfo: PlaceCardInfo) {
    nameLabel.text = placeInfo.name
    addressLabel.setText(placeInfo.address)
    setInfoLabel(distanceText: placeInfo.distanceText, ratingText: placeInfo.ratingText)
  }
  
  func updatePhotos(_ newPhotos: [UIImage]) {
    self.photos = newPhotos
    imageCarousel.reloadData()
  }
  
  private func setInfoLabel(distanceText: String, ratingText: String) {
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
extension MyCollectionCell: UICollectionViewDataSource {
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

// MARK: - UICollectionViewDelegateFlowLayout
extension MyCollectionCell: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(width: 135, height: 135)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return 8
  }
}
