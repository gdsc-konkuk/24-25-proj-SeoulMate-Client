//
//  AIChatViewController.swift
//  SeoulMate
//
//  Created by 박성근 on 3/27/25.
//

import UIKit
import SnapKit

final class AIChatViewController: UIViewController {
  // MARK: - Properties
  private var placeInfo: PlaceCardInfo?
  
  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }
  
  // MARK: - Configuration
  func configure(with placeInfo: PlaceCardInfo) {
    self.placeInfo = placeInfo
    title = placeInfo.name
  }
  
  // MARK: - Setup
  private func setupUI() {
    view.backgroundColor = .cyan
  }
}
