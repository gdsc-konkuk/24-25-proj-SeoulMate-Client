//
//  PlaceCardsContainerView.swift
//  SeoulMate
//
//  Created by 박성근 on 5/4/25.
//

import UIKit
import SnapKit

protocol PlaceCardsContainerDelegate: AnyObject {
  func didSelectPlace(at index: Int, placeInfo: PlaceCardInfo)
  func didScrollToPlace(at index: Int, placeInfo: PlaceCardInfo)
}

final class PlaceCardsContainerView: UIView {
  
  // MARK: - Properties
  weak var delegate: PlaceCardsContainerDelegate?
  
  private var places: [PlaceCardInfo] = []
  private var currentIndex: Int = 0
  
  private lazy var collectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.minimumLineSpacing = 16
    layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.backgroundColor = .clear
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.decelerationRate = .fast
    collectionView.delegate = self
    collectionView.dataSource = self
    collectionView.register(PlaceCardCell.self, forCellWithReuseIdentifier: PlaceCardCell.identifier)
    
    return collectionView
  }()
  
  private let pageControl: UIPageControl = {
    let pageControl = UIPageControl()
    pageControl.currentPageIndicatorTintColor = .main500
    pageControl.pageIndicatorTintColor = .gray300
    pageControl.hidesForSinglePage = true
    return pageControl
  }()
  
  // MARK: - Initialization
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
    backgroundColor = .clear
    
    addSubview(collectionView)
    addSubview(pageControl)
    
    collectionView.snp.makeConstraints { make in
      make.top.leading.trailing.equalToSuperview()
      make.height.equalTo(180)
    }
    
    pageControl.snp.makeConstraints { make in
      make.top.equalTo(collectionView.snp.bottom).offset(8)
      make.centerX.equalToSuperview()
      make.bottom.equalToSuperview().offset(-8)
    }
  }
  
  // MARK: - Public Methods
  func configure(with places: [PlaceCardInfo]) {
    Logger.log("PlaceCardsContainerView - 카드 구성: \(places.count)개의 장소")
    self.places = places
    pageControl.numberOfPages = places.count
    pageControl.currentPage = 0
    currentIndex = 0
    collectionView.reloadData()
    
    // 컬렉션 뷰가 실제로 업데이트되었는지 확인
    DispatchQueue.main.async {
      Logger.log("컬렉션 뷰 아이템 수: \(self.collectionView.numberOfItems(inSection: 0))")
      if !self.places.isEmpty && self.collectionView.numberOfItems(inSection: 0) > 0 {
        self.collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredHorizontally, animated: false)
      }
    }
  }
  
  func scrollToIndex(_ index: Int, animated: Bool = true) {
    guard index < places.count else { return }
    let indexPath = IndexPath(item: index, section: 0)
    collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
    currentIndex = index
    pageControl.currentPage = index
  }
  
  func currentPlace() -> PlaceCardInfo? {
    guard currentIndex < places.count else { return nil }
    return places[currentIndex]
  }
}

// MARK: - UICollectionViewDataSource
extension PlaceCardsContainerView: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return places.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PlaceCardCell.identifier, for: indexPath) as? PlaceCardCell else {
      return UICollectionViewCell()
    }
    
    let place = places[indexPath.item]
    cell.configure(with: place)
    return cell
  }
}

// MARK: - UICollectionViewDelegate
extension PlaceCardsContainerView: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let place = places[indexPath.item]
    delegate?.didSelectPlace(at: indexPath.item, placeInfo: place)
  }
  
  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    let center = CGPoint(x: scrollView.contentOffset.x + (scrollView.frame.width / 2), y: (scrollView.frame.height / 2))
    if let indexPath = collectionView.indexPathForItem(at: center) {
      currentIndex = indexPath.item
      pageControl.currentPage = currentIndex
      delegate?.didScrollToPlace(at: currentIndex, placeInfo: places[currentIndex])
    }
  }
  
  func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
    let cellWidth = collectionView.bounds.width - 60
    let cellSpacing = layout.minimumLineSpacing
    let cellWidthIncludingSpacing = cellWidth + cellSpacing
    let inset = layout.sectionInset.left

    let proposedOffsetX = targetContentOffset.pointee.x
    let currentOffsetX = scrollView.contentOffset.x

    // 현재 인덱스
    let currentIndex = round((currentOffsetX + inset) / cellWidthIncludingSpacing)
    // 이동 방향 및 거리
    let offsetDiff = proposedOffsetX - currentOffsetX

    var targetIndex = currentIndex

    // velocity가 크거나, 드래그 거리가 셀의 1/3 이상이면 다음/이전 카드로 이동
    if abs(velocity.x) > 0.2 {
        targetIndex += velocity.x > 0 ? 1 : -1
    } else if abs(offsetDiff) > cellWidthIncludingSpacing / 3 {
        targetIndex += offsetDiff > 0 ? 1 : -1
    }
    // 인덱스 범위 제한
    targetIndex = max(0, min(CGFloat(places.count - 1), targetIndex))

    let newOffsetX = targetIndex * cellWidthIncludingSpacing - inset
    targetContentOffset.pointee = CGPoint(x: newOffsetX, y: targetContentOffset.pointee.y)
  }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension PlaceCardsContainerView: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let width = collectionView.bounds.width - 60 // 좌우 여백 고려
    return CGSize(width: width, height: 160)
  }
}

// MARK: - Animation Extensions
extension PlaceCardsContainerView {
  func show(animated: Bool = true) {
    guard animated else {
      alpha = 1
      isHidden = false
      return
    }
    
    isHidden = false
    alpha = 0
    transform = CGAffineTransform(translationX: 0, y: 100)
    
    UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut]) {
      self.alpha = 1
      self.transform = .identity
    }
  }
  
  func hide(animated: Bool = true) {
    guard animated else {
      alpha = 0
      isHidden = true
      return
    }
    
    UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseIn]) {
      self.alpha = 0
      self.transform = CGAffineTransform(translationX: 0, y: 100)
    } completion: { _ in
      self.isHidden = true
      self.transform = .identity
    }
  }
}
