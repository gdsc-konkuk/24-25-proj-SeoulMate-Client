//
//  PlaceDetailPopupView.swift
//  SeoulMate
//
//  Created by 박성근 on 4/1/25.
//  Updated on 4/3/25.
//

import UIKit
import SnapKit
import Combine
import Kingfisher

final class PlaceDetailPopupView: UIView {
  
  // MARK: - Properties
  
  private var place: PlaceInfo?
  private var placeImages: [PlaceImage] = []
  private var cancellables = Set<AnyCancellable>()
  private let placeImageUseCase: FetchPlaceImagesUseCaseProtocol? = DIContainer.shared.resolve(type: FetchPlaceImagesUseCaseProtocol.self)
  
  var onDismiss: (() -> Void)?
  var onShareButtonTapped: ((PlaceInfo) -> Void)?
  
  // MARK: - UI Components
  
  private lazy var backgroundOverlayView: UIView = {
    let view = UIView()
    view.backgroundColor = .black.withAlphaComponent(0.5)
    
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
    view.addGestureRecognizer(tapGesture)
    
    return view
  }()
  
  private lazy var containerView: UIView = {
    let view = UIView()
    view.backgroundColor = .white
    view.layer.cornerRadius = 16
    view.clipsToBounds = true
    return view
  }()
  
  private lazy var dismissButton: UIButton = {
    let button = UIButton(type: .system)
    button.setImage(UIImage(systemName: "xmark"), for: .normal)
    button.tintColor = .darkGray
    button.addTarget(self, action: #selector(dismissButtonTapped), for: .touchUpInside)
    return button
  }()
  
  private lazy var imageScrollView: UIScrollView = {
    let scrollView = UIScrollView()
    scrollView.isPagingEnabled = true
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.delegate = self
    return scrollView
  }()
  
  private lazy var pageControl: UIPageControl = {
    let pageControl = UIPageControl()
    pageControl.currentPage = 0
    pageControl.numberOfPages = 1
    pageControl.pageIndicatorTintColor = .systemGray5
    pageControl.currentPageIndicatorTintColor = .systemBlue
    return pageControl
  }()
  
  private lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 22, weight: .bold)
    label.textColor = .black
    label.numberOfLines = 0
    return label
  }()
  
  private lazy var addressLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 14)
    label.textColor = .darkGray
    label.numberOfLines = 0
    return label
  }()
  
  private lazy var infoStackView: UIStackView = {
    let stackView = UIStackView()
    stackView.axis = .vertical
    stackView.spacing = 16
    stackView.distribution = .fill
    return stackView
  }()
  
  private lazy var buttonStackView: UIStackView = {
    let stackView = UIStackView()
    stackView.axis = .horizontal
    stackView.spacing = 16
    stackView.distribution = .fillEqually
    return stackView
  }()
  
  private lazy var shareButton: UIButton = {
    let button = UIButton(type: .system)
    button.setTitle("공유하기", for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
    button.backgroundColor = .systemGray5
    button.tintColor = .black
    button.layer.cornerRadius = 8
    button.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
    return button
  }()
  
  // MARK: - Initialization
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupViews()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Setup Methods
  
  private func setupViews() {
    // 배경 오버레이 뷰 추가
    addSubview(backgroundOverlayView)
    backgroundOverlayView.frame = bounds
    
    // 컨테이너 뷰 및 기타 UI 요소 추가
    addSubview(containerView)
    containerView.addSubview(dismissButton)
    containerView.addSubview(imageScrollView)
    containerView.addSubview(pageControl)
    containerView.addSubview(titleLabel)
    containerView.addSubview(addressLabel)
    containerView.addSubview(infoStackView)
    containerView.addSubview(buttonStackView)
    
    buttonStackView.addArrangedSubview(shareButton)
    
    // 컨테이너 뷰 제약 조건
    containerView.snp.makeConstraints { make in
      make.center.equalToSuperview()
      make.height.equalToSuperview().multipliedBy(0.7)
      make.width.equalToSuperview().multipliedBy(0.8)
    }
    
    // 배경 오버레이 뷰 제약 조건
    backgroundOverlayView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
    
    // 닫기 버튼 제약 조건
    dismissButton.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(16)
      make.right.equalToSuperview().offset(-16)
      make.width.height.equalTo(28)
    }
    
    // 이미지 스크롤 뷰 제약 조건
    imageScrollView.snp.makeConstraints { make in
      make.top.left.right.equalToSuperview()
      make.height.equalTo(200)
    }
    
    // 페이지 컨트롤 제약 조건
    pageControl.snp.makeConstraints { make in
      make.bottom.equalTo(imageScrollView.snp.bottom).offset(-8)
      make.centerX.equalToSuperview()
      make.height.equalTo(20)
    }
    
    // 제목 제약 조건
    titleLabel.snp.makeConstraints { make in
      make.top.equalTo(imageScrollView.snp.bottom).offset(16)
      make.left.equalToSuperview().offset(16)
      make.right.equalToSuperview().offset(-16)
    }
    
    // 주소 제약 조건
    addressLabel.snp.makeConstraints { make in
      make.top.equalTo(titleLabel.snp.bottom).offset(8)
      make.left.equalToSuperview().offset(16)
      make.right.equalToSuperview().offset(-16)
    }
    
    // 정보 스택 뷰 제약 조건
    infoStackView.snp.makeConstraints { make in
      make.top.equalTo(addressLabel.snp.bottom).offset(16)
      make.left.equalToSuperview().offset(16)
      make.right.equalToSuperview().offset(-16)
    }
    
    // 버튼 스택 뷰 제약 조건
    buttonStackView.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(16)
      make.right.equalToSuperview().offset(-16)
      make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-16)
      make.height.equalTo(50)
    }
  }
  
  // MARK: - Public Methods
  
  func configure(with place: PlaceInfo) {
    self.place = place
    
    titleLabel.text = place.name
    addressLabel.text = place.address
    
    // 이미지 슬라이드쇼 초기 설정 (로딩 상태)
    setupPlaceholderImageSlideshow()
    
    // 이미지 로드
    loadImages(for: place)
    
    // 추가 정보가 있는 경우 표시 (실제 앱에서는 API에서 가져온 데이터로 채우기)
    let openHoursInfo = createInfoLabel(title: "영업시간", content: "오전 9시 - 오후 6시 (월요일 휴무)")
    let infoLabel = createInfoLabel(title: "소개", content: "경복궁은 조선왕조 제일의 법궁으로 1395년에 창건되었습니다. 북으로 북악산을 기대어 자리 잡았고 정문인 광화문을 중심으로 하여 왕과 신하들의 정무 시설을 갖추고 있습니다.")
    let contactInfo = createInfoLabel(title: "연락처", content: "02-1234-5678")
    
    // 기존 내용 제거
    infoStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
    
    // 새 내용 추가
    infoStackView.addArrangedSubview(openHoursInfo)
    infoStackView.addArrangedSubview(infoLabel)
    infoStackView.addArrangedSubview(contactInfo)
  }
  
  // MARK: - Private Methods
  
  private func loadImages(for place: PlaceInfo) {
    Logger.log(message: "DetailPopup: 이미지 로딩 시작 - \(place.name)")
    
    // 1. Google Places ID로 이미지 로드
    if let placeId = place.placeId {
      loadPlaceImages(placeId: placeId)
    }
    // 2. imageURL로 이미지 로드
    else if let imageURL = place.imageURL, let url = URL(string: imageURL) {
      loadKingfisherImage(url: url)
    } else {
      Logger.log(message: "DetailPopup: 이미지 URL과 placeId 모두 없음")
    }
  }
  
  private func loadPlaceImages(placeId: String) {
    guard let placeImageUseCase = self.placeImageUseCase else {
      Logger.log(message: "DetailPopup: placeImageUseCase가 nil - DI 주입 실패")
      return
    }
    
    let maxSize = CGSize(width: UIScreen.main.bounds.width, height: 300)
    let cacheKey = "place_detail_\(placeId)"
    
    Logger.log(message: "DetailPopup: Places API로 이미지 로드 시작 - \(placeId)")
    
    placeImageUseCase.execute(placeId: placeId, maxSize: maxSize)
      .receive(on: DispatchQueue.main)
      .sink(
        receiveCompletion: { [weak self] completion in
          guard let self = self else { return }
          
          if case .failure(let error) = completion {
            Logger.log(message: "DetailPopup: 이미지 로드 실패 - \(error.localizedDescription)")
            self.setupErrorImageSlideshow()
          }
        },
        receiveValue: { [weak self] placeImages in
          guard let self = self else { return }
          
          if placeImages.isEmpty {
            Logger.log(message: "DetailPopup: 이미지 없음 - \(placeId)")
            self.setupErrorImageSlideshow()
            return
          }
          
          Logger.log(message: "DetailPopup: 이미지 로드 성공 - \(placeImages.count)개")
          self.placeImages = placeImages
          self.updateImageSlideshow()
          
          // 이미지를 Kingfisher 캐시에 저장 (재사용을 위해)
          for (index, image) in placeImages.enumerated() {
            KingfisherManager.shared.cache.store(
              image.image,
              forKey: "\(cacheKey)_\(index)",
              options: KingfisherParsedOptionsInfo([.diskCacheExpiration(.days(7))]),
              toDisk: true
            )
          }
        }
      )
      .store(in: &cancellables)
  }
  
  private func loadKingfisherImage(url: URL) {
    Logger.log(message: "DetailPopup: Kingfisher로 이미지 로드 시작 - \(url.absoluteString)")
    
    let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: frame.width, height: 200))
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    
    // 기존 이미지 뷰 제거
    imageScrollView.subviews.forEach { $0.removeFromSuperview() }
    
    // Kingfisher로 이미지 로드
    imageView.kf.setImage(
      with: url,
      placeholder: UIImage(systemName: "photo"),
      options: [
        .transition(.fade(0.3)),
        .cacheOriginalImage,
        .retryStrategy(DelayRetryStrategy(maxRetryCount: 3))
      ],
      completionHandler: { [weak self] result in
        guard let self = self else { return }
        
        switch result {
        case .success(let value):
          Logger.log(message: "DetailPopup: Kingfisher 이미지 로드 성공 - 크기: \(value.image.size.width)x\(value.image.size.height)")
          
          // 이미지 스크롤 뷰에 추가
          self.imageScrollView.addSubview(imageView)
          self.imageScrollView.contentSize = CGSize(width: self.frame.width, height: 200)
          
          // 페이지 컨트롤 업데이트
          self.pageControl.numberOfPages = 1
          self.pageControl.currentPage = 0
        case .failure(let error):
          Logger.log(message: "DetailPopup: Kingfisher 이미지 로드 실패 - \(error.localizedDescription)")
          self.setupErrorImageSlideshow()
        }
      })
  }
  
  // 로딩 중 이미지 슬라이드쇼 설정
  private func setupPlaceholderImageSlideshow() {
    // 기존 이미지 뷰 제거
    imageScrollView.subviews.forEach { $0.removeFromSuperview() }
    
    // 로딩 표시 이미지
    let placeholderImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: frame.width, height: 200))
    placeholderImageView.contentMode = .scaleAspectFit
    placeholderImageView.clipsToBounds = true
    placeholderImageView.image = UIImage(systemName: "arrow.clockwise")
    placeholderImageView.tintColor = .systemGray
    placeholderImageView.backgroundColor = UIColor(white: 0.95, alpha: 1)
    
    imageScrollView.addSubview(placeholderImageView)
    
    // 이미지 스크롤 뷰 컨텐츠 사이즈 설정
    imageScrollView.contentSize = CGSize(width: frame.width, height: 200)
    
    // 페이지 컨트롤 업데이트
    pageControl.numberOfPages = 1
    pageControl.currentPage = 0
  }
  
  // 오류 발생 시 이미지 슬라이드쇼 설정
  private func setupErrorImageSlideshow() {
    // 기존 이미지 뷰 제거
    imageScrollView.subviews.forEach { $0.removeFromSuperview() }
    
    // 오류 표시 이미지
    let errorImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: frame.width, height: 200))
    errorImageView.contentMode = .scaleAspectFit
    errorImageView.clipsToBounds = true
    errorImageView.image = UIImage(systemName: "exclamationmark.triangle")
    errorImageView.tintColor = .systemOrange
    errorImageView.backgroundColor = UIColor(white: 0.95, alpha: 1)
    
    imageScrollView.addSubview(errorImageView)
    
    // 이미지 스크롤 뷰 컨텐츠 사이즈 설정
    imageScrollView.contentSize = CGSize(width: frame.width, height: 200)
    
    // 페이지 컨트롤 업데이트
    pageControl.numberOfPages = 1
    pageControl.currentPage = 0
  }
  
  private func updateImageSlideshow() {
    // 기존 이미지 뷰 제거
    imageScrollView.subviews.forEach { $0.removeFromSuperview() }
    
    // 이미지가 없는 경우
    if placeImages.isEmpty {
      setupErrorImageSlideshow()
      return
    }
    
    // 이미지 추가
    for (i, placeImage) in placeImages.enumerated() {
      let imageView = UIImageView()
      imageView.contentMode = .scaleAspectFill
      imageView.clipsToBounds = true
      imageView.image = placeImage.image
      
      // 이미지 뷰 프레임 설정
      let xPos = CGFloat(i) * frame.width
      imageView.frame = CGRect(x: xPos, y: 0, width: frame.width, height: 200)
      
      imageScrollView.addSubview(imageView)
      
      // 저작자 표시가 필요한 경우
      if let attribution = placeImage.attribution, !attribution.isEmpty {
        addAttributionLabel(to: imageView, text: attribution)
      }
    }
    
    // 이미지 스크롤 뷰 컨텐츠 사이즈 설정
    imageScrollView.contentSize = CGSize(width: frame.width * CGFloat(placeImages.count), height: 200)
    
    // 페이지 컨트롤 업데이트
    pageControl.numberOfPages = placeImages.count
    pageControl.currentPage = 0
  }
  
  private func createInfoLabel(title: String, content: String) -> UILabel {
    let label = UILabel()
    let attributedText = NSMutableAttributedString()
    
    // 제목 부분
    let titleAttributes: [NSAttributedString.Key: Any] = [
      .font: UIFont.systemFont(ofSize: 14, weight: .bold),
      .foregroundColor: UIColor.black
    ]
    attributedText.append(NSAttributedString(string: "\(title): ", attributes: titleAttributes))
    
    // 내용 부분
    let contentAttributes: [NSAttributedString.Key: Any] = [
      .font: UIFont.systemFont(ofSize: 14),
      .foregroundColor: UIColor.darkGray
    ]
    attributedText.append(NSAttributedString(string: content, attributes: contentAttributes))
    
    label.attributedText = attributedText
    label.numberOfLines = 0
    
    return label
  }
  
  private func addAttributionLabel(to imageView: UIImageView, text: String) {
    let attributionLabel = UILabel()
    attributionLabel.text = text
    attributionLabel.font = UIFont.systemFont(ofSize: 10)
    attributionLabel.textColor = .white
    attributionLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    attributionLabel.textAlignment = .right
    attributionLabel.numberOfLines = 1
    
    imageView.addSubview(attributionLabel)
    attributionLabel.frame = CGRect(
      x: 0,
      y: imageView.frame.height - 20,
      width: imageView.frame.width,
      height: 20
    )
  }
  
  // MARK: - Actions
  
  @objc private func dismissButtonTapped() {
    onDismiss?()
  }
  
  @objc private func backgroundTapped(_ gesture: UITapGestureRecognizer) {
    // 배경 오버레이 영역을 탭했을 때만 닫기 (컨테이너 뷰는 제외)
    let location = gesture.location(in: self)
    if !containerView.frame.contains(location) {
      onDismiss?()
    }
  }
  
  @objc private func shareButtonTapped() {
    if let place = place {
      onShareButtonTapped?(place)
    }
  }
}

// MARK: - UIScrollViewDelegate

extension PlaceDetailPopupView: UIScrollViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let pageWidth = scrollView.bounds.width
    let currentPage = Int((scrollView.contentOffset.x + pageWidth / 2) / pageWidth)
    
    if currentPage >= 0 && currentPage < pageControl.numberOfPages {
      pageControl.currentPage = currentPage
    }
  }
}
