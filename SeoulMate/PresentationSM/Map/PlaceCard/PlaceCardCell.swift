//
//  PlaceCardCell.swift
//  SeoulMate
//
//  Created by 박성근 on 4/1/25.
//

import UIKit
import Combine
import SnapKit
import Kingfisher

// MARK: - Card Info
struct PlaceInfo {
  let id: String
  let name: String
  let address: String
  var imageURL: String?
  let distance: Double
  let coordinate: (Double, Double)
  var placeId: String? // Google Places ID 추가
}

final class PlaceCardCell: UICollectionViewCell {
  static let identifier = "PlaceCardCell"
  
  // MARK: - Properties
  private var cancellables = Set<AnyCancellable>()
  private var imageTask: Cancellable?
  private let placeImageUseCase: FetchPlaceImagesUseCaseProtocol? = DIContainer.shared.resolve(type: FetchPlaceImagesUseCaseProtocol.self)
  
  // MARK: - UI Components
  private lazy var containerView: UIView = {
    let view = UIView()
    view.backgroundColor = .white
    view.layer.cornerRadius = 12
    view.layer.shadowColor = UIColor.black.cgColor
    view.layer.shadowOpacity = 0.1
    view.layer.shadowOffset = CGSize(width: 0, height: 2)
    view.layer.shadowRadius = 4
    view.clipsToBounds = false
    return view
  }()
  
  private lazy var imageContainerView: UIView = {
    let view = UIView()
    view.clipsToBounds = true
    view.layer.cornerRadius = 8
    view.backgroundColor = UIColor(white: 0.95, alpha: 1)
    return view
  }()
  
  private lazy var placeImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    imageView.layer.cornerRadius = 8
    return imageView
  }()
  
  private lazy var infoContainerView: UIView = {
    let view = UIView()
    view.backgroundColor = .clear
    return view
  }()
  
  private lazy var nameLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
    label.textColor = .black
    label.numberOfLines = 1
    return label
  }()
  
  private lazy var addressLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 12)
    label.textColor = .darkGray
    label.numberOfLines = 2
    return label
  }()
  
  private lazy var distanceContainer: UIView = {
    let view = UIView()
    view.backgroundColor = .clear
    return view
  }()
  
  private lazy var locationIconImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.image = UIImage(systemName: "location.fill")
    imageView.tintColor = .systemBlue
    imageView.contentMode = .scaleAspectFit
    return imageView
  }()
  
  private lazy var distanceLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
    label.textColor = .systemBlue
    return label
  }()
  
  // MARK: - Initialization
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupViews()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    
    // 기존 코드 유지 (이미 있는 코드)
    placeImageView.image = nil
    nameLabel.text = nil
    addressLabel.text = nil
    distanceLabel.text = nil
    
    placeImageView.kf.cancelDownloadTask()
    imageTask?.cancel()
    imageTask = nil
    
    containerView.backgroundColor = .white
    containerView.layer.borderWidth = 0
    nameLabel.textColor = .black
    addressLabel.textColor = .darkGray
    distanceContainer.isHidden = false
    placeImageView.tintColor = .gray
    placeImageView.backgroundColor = UIColor(white: 0.95, alpha: 1)
  }
  
  // MARK: - Setup Methods
  
  private func setupViews() {
    contentView.addSubview(containerView)
    containerView.addSubview(imageContainerView)
    imageContainerView.addSubview(placeImageView)
    containerView.addSubview(infoContainerView)
    
    infoContainerView.addSubview(nameLabel)
    infoContainerView.addSubview(addressLabel)
    infoContainerView.addSubview(distanceContainer)
    
    distanceContainer.addSubview(locationIconImageView)
    distanceContainer.addSubview(distanceLabel)
    
    // 전체 컨테이너 제약 조건
    containerView.snp.makeConstraints { make in
      make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
    }
    
    // 이미지 컨테이너 제약 조건
    imageContainerView.snp.makeConstraints { make in
      make.leading.equalToSuperview().offset(12)
      make.centerY.equalToSuperview()
      make.width.height.equalTo(80)
    }
    
    // 이미지 제약 조건
    placeImageView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
    
    // 정보 컨테이너 제약 조건
    infoContainerView.snp.makeConstraints { make in
      make.leading.equalTo(imageContainerView.snp.trailing).offset(16)
      make.trailing.equalToSuperview().offset(-12)
      make.top.bottom.equalToSuperview().inset(12)
    }
    
    // 이름 레이블 제약 조건
    nameLabel.snp.makeConstraints { make in
      make.top.leading.trailing.equalToSuperview()
    }
    
    // 주소 레이블 제약 조건
    addressLabel.snp.makeConstraints { make in
      make.top.equalTo(nameLabel.snp.bottom).offset(4)
      make.leading.trailing.equalToSuperview()
    }
    
    // 거리 컨테이너 제약 조건
    distanceContainer.snp.makeConstraints { make in
      make.top.equalTo(addressLabel.snp.bottom).offset(8)
      make.leading.bottom.equalToSuperview()
      make.height.equalTo(16)
    }
    
    // 위치 아이콘 제약 조건
    locationIconImageView.snp.makeConstraints { make in
      make.leading.equalToSuperview()
      make.centerY.equalToSuperview()
      make.width.height.equalTo(12)
    }
    
    // 거리 레이블 제약 조건
    distanceLabel.snp.makeConstraints { make in
      make.leading.equalTo(locationIconImageView.snp.trailing).offset(4)
      make.centerY.equalToSuperview()
    }
  }
  
  // MARK: - Configuration
  func configure(with place: PlaceInfo) {
    nameLabel.text = place.name
    addressLabel.text = place.address
    distanceLabel.text = String(format: "%.1fkm", place.distance)
    
    // 이미지 표시 로직
    setupImage(for: place)
  }
  
  private func setupImage(for place: PlaceInfo) {
    // 기본 이미지 설정
    let placeholderImage = UIImage(systemName: "photo")
    placeImageView.image = placeholderImage
    placeImageView.tintColor = .gray
    
    // 1. Google Places ID를 통한 이미지 로드
    if let placeId = place.placeId {
      loadPlaceImage(placeId: placeId)
    }
    // 2. imageURL이 있는 경우 Kingfisher를 통한 이미지 로드
    else if let imageURL = place.imageURL, let url = URL(string: imageURL) {
      placeImageView.kf.setImage(
        with: url,
        placeholder: placeholderImage,
        options: [
          .transition(.fade(0.3)),
          .cacheOriginalImage,
          .retryStrategy(DelayRetryStrategy(maxRetryCount: 3))
        ]
      ) { [weak self] result in
        switch result {
        case .success(_):
          break
        case .failure(let error):
          print("Kingfisher 이미지 로드 실패: \(error.localizedDescription)")
          self?.placeImageView.image = placeholderImage
          self?.placeImageView.tintColor = .gray
        }
      }
    }
  }
  
  private func loadPlaceImage(placeId: String) {
    // UseCase 작업 취소
    imageTask?.cancel()
    
    // 캐시 키 생성
    let cacheKey = "place_\(placeId)"
    
    // 1. 먼저 Kingfisher 캐시에서 확인 (메모리 캐시)
    if let cachedImage = KingfisherManager.shared.cache.retrieveImageInMemoryCache(forKey: cacheKey) {
      self.placeImageView.image = cachedImage
      return
    }
    
    // 2. 디스크 캐시 확인 (비동기 호출 처리)
    KingfisherManager.shared.cache.retrieveImageInDiskCache(forKey: cacheKey) { [weak self] result in
      switch result {
      case .success(let image):
        if let image = image {
          DispatchQueue.main.async {
            self?.placeImageView.image = image
          }
          return
        }
        // 캐시에 없는 경우 Places API 호출
        self?.loadImageFromPlacesAPI(placeId: placeId, maxSize: CGSize(width: 300, height: 300), cacheKey: cacheKey)
      case .failure(_):
        // 캐시 접근 실패 시 Places API 호출
        self?.loadImageFromPlacesAPI(placeId: placeId, maxSize: CGSize(width: 300, height: 300), cacheKey: cacheKey)
      }
    }
  }
  
  private func loadImageFromPlacesAPI(placeId: String, maxSize: CGSize, cacheKey: String) {
    imageTask = placeImageUseCase?.executeForFirstImage(placeId: placeId, maxSize: maxSize)
      .receive(on: DispatchQueue.main)
      .sink(
        receiveCompletion: { [weak self] completion in
          if case .failure(let error) = completion {
            print("Places 이미지 로드 실패: \(error.localizedDescription)")
            self?.placeImageView.image = UIImage(systemName: "photo")
            self?.placeImageView.tintColor = .gray
          }
        },
        receiveValue: { [weak self] placeImage in
          guard let self = self else { return }
          
          if let placeImage = placeImage {
            self.placeImageView.image = placeImage.image
            
            // Kingfisher 캐시에 이미지 저장
            KingfisherManager.shared.cache.store(
              placeImage.image,
              forKey: cacheKey,
              options: KingfisherParsedOptionsInfo([]),
              toDisk: true
            )
            
            // 저작자 표시가 필요한 경우
            if let attribution = placeImage.attribution, !attribution.isEmpty {
              self.addAttributionLabel(text: attribution)
            }
          } else {
            self.placeImageView.image = UIImage(systemName: "photo")
            self.placeImageView.tintColor = .gray
          }
        }
      )
  }
  
  private func addAttributionLabel(text: String) {
    // 기존 저작자 표시 레이블이 있으면 제거
    imageContainerView.subviews.forEach { view in
      if view is UILabel {
        view.removeFromSuperview()
      }
    }
    
    // 저작자 표시 레이블 추가
    let attributionLabel = UILabel()
    attributionLabel.text = text
    attributionLabel.font = UIFont.systemFont(ofSize: 8)
    attributionLabel.textColor = .white
    attributionLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    attributionLabel.textAlignment = .right
    attributionLabel.numberOfLines = 1
    
    imageContainerView.addSubview(attributionLabel)
    attributionLabel.snp.makeConstraints { make in
      make.bottom.left.right.equalToSuperview()
      make.height.equalTo(12)
    }
  }
}

// TODO: 삭제
extension PlaceInfo {
  // 빈 PlaceInfo 객체 생성을 위한 정적 메서드
  static func createEmpty(index: Int) -> PlaceInfo {
    return PlaceInfo(
      id: "empty_\(index)",
      name: "추천 장소를 찾아보세요",
      address: "지도에서 장소를 검색하거나 선택해보세요",
      imageURL: nil,
      distance: 0.0,
      coordinate: (0, 0),
      placeId: nil
    )
  }
  
  // 빈 카드인지 확인하는 속성
  var isEmpty: Bool {
    return id.starts(with: "empty_")
  }
}

extension PlaceCardCell {
  // 빈 카드일 때 스타일 적용
  func applyEmptyStyle() {
    // 이미지를 플레이스홀더로 설정
    placeImageView.image = UIImage(systemName: "map")
    placeImageView.tintColor = UIColor.systemGray3
    placeImageView.backgroundColor = UIColor(white: 0.95, alpha: 1)
    
    // 컨테이너 스타일 변경
    containerView.backgroundColor = UIColor(white: 0.98, alpha: 1)
    containerView.layer.borderColor = UIColor.systemGray4.cgColor
    containerView.layer.borderWidth = 1
    
    // 거리 정보 숨기기
    distanceContainer.isHidden = true
    
    // 이름과 주소 스타일 변경
    nameLabel.textColor = .systemGray
    addressLabel.textColor = .systemGray3
  }
}
