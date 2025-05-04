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
    self.places = places
    pageControl.numberOfPages = places.count
    pageControl.currentPage = 0
    currentIndex = 0
    collectionView.reloadData()
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
