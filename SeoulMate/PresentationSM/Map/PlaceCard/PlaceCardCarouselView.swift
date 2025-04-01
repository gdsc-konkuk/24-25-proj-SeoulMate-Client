//
//  PlaceCardCarouselView.swift
//  SeoulMate
//
//  Created by 박성근 on 4/1/25.
//

import UIKit
import SnapKit
import CoreLocation

final class PlaceCardCarouselView: UIView {
  
  // MARK: - Constants
  
  private let cardsCount = 5 // 항상 5개 카드 표시
  
  // MARK: - Properties
  
  private var places: [PlaceInfo] = []
  private var displayPlaces: [PlaceInfo] = [] // 실제 표시할 장소 목록 (빈 카드 포함)
  var onPlaceSelected: ((PlaceInfo) -> Void)?
  
  // MARK: - UI Components
  
  private lazy var collectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.minimumLineSpacing = 20
    layout.minimumInteritemSpacing = 0
    layout.itemSize = CGSize(width: UIScreen.main.bounds.width - 80, height: 110)
    
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.backgroundColor = .clear
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.isPagingEnabled = false
    collectionView.decelerationRate = .fast
    collectionView.contentInset = UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 40)
    collectionView.register(PlaceCardCell.self, forCellWithReuseIdentifier: PlaceCardCell.identifier)
    collectionView.delegate = self
    collectionView.dataSource = self
    return collectionView
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
    backgroundColor = .clear
    addSubview(collectionView)
    
    collectionView.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(8)
      make.leading.trailing.equalToSuperview()
      make.bottom.equalToSuperview().offset(-8)
    }
  }
  
  // MARK: - Public Methods
  
  func setPlaces(_ places: [PlaceInfo]) {
    self.places = places
    
    // 표시할 장소 목록 생성 (실제 장소 + 빈 카드)
    createDisplayPlaces()
    
    collectionView.reloadData()
    
    // 실제 장소가 있는 경우 첫 번째 실제 장소로 스크롤
    DispatchQueue.main.async {
      if !self.places.isEmpty {
        self.collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredHorizontally, animated: false)
      }
    }
  }
  
  func scrollToPlace(at index: Int, animated: Bool = true) {
    guard index >= 0 && index < displayPlaces.count else { return }
    
    let indexPath = IndexPath(item: index, section: 0)
    DispatchQueue.main.async {
      self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
    }
  }
  
  // MARK: - Private Methods
  
  private func createDisplayPlaces() {
    displayPlaces = places
    
    // 장소가 5개 미만이면 빈 카드를 추가
    if displayPlaces.count < cardsCount {
      let emptyCount = cardsCount - displayPlaces.count
      for i in 0..<emptyCount {
        displayPlaces.append(PlaceInfo.createEmpty(index: i))
      }
    }
  }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate

extension PlaceCardCarouselView: UICollectionViewDataSource, UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return displayPlaces.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PlaceCardCell.identifier, for: indexPath) as? PlaceCardCell,
          indexPath.item < displayPlaces.count else {
      return UICollectionViewCell()
    }
    
    let place = displayPlaces[indexPath.item]
    cell.configure(with: place)
    
    // 빈 카드인 경우 스타일 변경
    if place.isEmpty {
      cell.applyEmptyStyle()
    }
    
    return cell
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard indexPath.item < displayPlaces.count else { return }
    
    let place = displayPlaces[indexPath.item]
    
    // 빈 카드가 아닌 경우에만 선택 이벤트 전달
    if !place.isEmpty {
      onPlaceSelected?(place)
    }
  }
  
  // 스크롤 스냅 효과 구현
  func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    // 컬렉션뷰 레이아웃 정보 가져오기
    guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
    
    // 완전한 카드 너비 (카드 + 간격)
    let cellWidth = layout.itemSize.width
    let cellSpacing = layout.minimumLineSpacing
    let cellWidthIncludingSpacing = cellWidth + cellSpacing
    
    // 스크롤 뷰의 좌측 inset 적용
    let inset = collectionView.contentInset.left
    
    // 현재 오프셋에 inset 추가하여 실제 위치 계산
    let offsetX = targetContentOffset.pointee.x + inset
    
    // 현재 오프셋을 기준으로 가장 가까운 셀 인덱스 계산
    var index = round(offsetX / cellWidthIncludingSpacing)
    
    // 스크롤 방향에 따라 다음/이전 카드로 스냅
    if offsetX - (index * cellWidthIncludingSpacing) > cellWidthIncludingSpacing / 2 {
      index += 1
    }
    
    // 스크롤 속도가 있는 경우 방향에 따라 조정
    if abs(velocity.x) > 0.3 {
      index = velocity.x > 0 ? ceil(offsetX / cellWidthIncludingSpacing) : floor(offsetX / cellWidthIncludingSpacing)
    }
    
    // 인덱스 범위 검사
    index = max(0, min(index, CGFloat(collectionView.numberOfItems(inSection: 0) - 1)))
    
    // inset을 고려한 최종 타겟 오프셋 설정
    targetContentOffset.pointee.x = index * cellWidthIncludingSpacing - inset
  }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension PlaceCardCarouselView: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(width: collectionView.frame.width - 80, height: 110)
  }
}
