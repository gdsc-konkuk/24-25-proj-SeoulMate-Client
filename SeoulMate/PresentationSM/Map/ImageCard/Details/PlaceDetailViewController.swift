//
//  PlaceDetailViewController.swift
//  SeoulMate
//
//  Created by 박성근 on 5/5/25.
//

import UIKit
import SnapKit

protocol PlaceDetailViewControllerDelegate: AnyObject {
  func placeDetailViewController(_ controller: PlaceDetailViewController, didDismissWith placeInfo: PlaceCardInfo?)
}

final class PlaceDetailViewController: UIViewController {
  weak var delegate: PlaceDetailViewControllerDelegate?
  let detailView = PlaceDetailView()
  private var placeInfo: PlaceCardInfo?
  private var isDismissedByAskToBot = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor.black.withAlphaComponent(0.3) // 반투명 배경
    setupDetailView()
    setupDismissGesture()
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    // Ask to Bot 버튼으로 인한 dismiss가 아닌 경우에만 delegate 호출
    if !isDismissedByAskToBot {
      delegate?.placeDetailViewController(self, didDismissWith: nil)
    }
  }
  
  private func setupDetailView() {
    view.addSubview(detailView)
    detailView.snp.makeConstraints { make in
      make.center.equalToSuperview()
      make.left.right.equalToSuperview().inset(16)
      make.height.equalTo(576)
    }
    
    detailView.delegate = self
  }
  
  private func setupDismissGesture() {
    let tap = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap(_:)))
    tap.cancelsTouchesInView = false
    view.addGestureRecognizer(tap)
  }
  
  @objc private func handleBackgroundTap(_ gesture: UITapGestureRecognizer) {
    let location = gesture.location(in: view)
    if !detailView.frame.contains(location) {
      dismiss(animated: false)
    }
  }
  
  func configure(with placeInfo: PlaceCardInfo, purposes: [String]) {
    self.placeInfo = placeInfo
    detailView.configure(with: placeInfo, purposes: purposes)
  }
}

// MARK: - PlaceDetailViewDelegate
extension PlaceDetailViewController: PlaceDetailViewDelegate {
  func didTapAskToBotButton(with placeInfo: PlaceCardInfo) {
    self.placeInfo = placeInfo
    isDismissedByAskToBot = true
    dismiss(animated: false) { [weak self] in
      self?.delegate?.placeDetailViewController(self!, didDismissWith: placeInfo)
    }
  }
  
  func didTapDismissButton(reason: DismissReason) {
    switch reason {
    case .askToBot:
      // This case is handled by didTapAskToBotButton
      break
    case .backgroundTap:
      isDismissedByAskToBot = false
    dismiss(animated: false)
    }
  }
}
