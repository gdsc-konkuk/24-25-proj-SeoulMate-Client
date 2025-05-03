//
//  TabBarController.swift
//  SeoulMate
//
//  Created on 3/27/25.
//

import UIKit
import SnapKit

// TODO: Setting 해야함.
enum TabItems: Int, CaseIterable {
  case map
  case aiChat
  case myPage
  
  var viewController: UIViewController {
    switch self {
    case .map:
      let vc = MapViewController()
      return vc
    case .aiChat:
      let vc = AIChatViewController()
      return vc
    case .myPage:
      let vc = MyPageViewController()
      return vc
    }
  }
  
  var icon: String {
    switch self {
    case .map:
      return "map"
    case .aiChat:
      return "message.fill"
    case .myPage:
      return "person"
    }
  }
  
  var title: String {
    switch self {
    case .map:
      return "지도"
    case .aiChat:
      return "AI 채팅"
    case .myPage:
      return "내 정보"
    }
  }
}

class TabBarController: UIViewController {
  
  // MARK: - Properties
  private var selectedTab: TabItems = .map
  private var currentViewController: UIViewController?
  private var viewControllers: [TabItems: UIViewController] = [:]
  
  // MARK: - UI Components
  private let tabBarView: UIView = {
    let view = UIView()
    view.backgroundColor = .white
    view.layer.shadowColor = UIColor.black.cgColor
    view.layer.shadowOffset = CGSize(width: 0, height: -2)
    view.layer.shadowOpacity = 0.1
    view.layer.shadowRadius = 4
    return view
  }()
  
  private let mapButton: UIButton = {
    let button = UIButton()
    button.setImage(UIImage(systemName: "map"), for: .normal)
    button.tintColor = .systemBlue
    return button
  }()
  
  private let myPageButton: UIButton = {
    let button = UIButton()
    button.setImage(UIImage(systemName: "person"), for: .normal)
    button.tintColor = .systemGray
    return button
  }()
  
  private let centerButton: UIButton = {
    let button = UIButton()
    button.backgroundColor = .systemBlue
    button.tintColor = .white
    button.layer.cornerRadius = 30
    button.setImage(UIImage(systemName: "message.fill"), for: .normal)
    button.layer.shadowColor = UIColor.black.cgColor
    button.layer.shadowOffset = CGSize(width: 0, height: 2)
    button.layer.shadowOpacity = 0.2
    button.layer.shadowRadius = 4
    return button
  }()
  
  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupUI()
    setupActions()
    switchToTab(.map)
  }
  
  // MARK: - Setup UI
  private func setupUI() {
    view.backgroundColor = .systemBackground
    
    // Add TabBar View
    view.addSubview(tabBarView)
    tabBarView.snp.makeConstraints { make in
      make.leading.trailing.bottom.equalToSuperview()
      make.height.equalTo(80)
    }
    
    // Add buttons to tabBar
    tabBarView.addSubview(mapButton)
    tabBarView.addSubview(myPageButton)
    view.addSubview(centerButton) // Overlap button
    
    mapButton.snp.makeConstraints { make in
      make.leading.equalTo(tabBarView).offset(50)
      make.centerY.equalTo(tabBarView)
      make.width.height.equalTo(44)
    }
    
    myPageButton.snp.makeConstraints { make in
      make.trailing.equalTo(tabBarView).offset(-50)
      make.centerY.equalTo(tabBarView)
      make.width.height.equalTo(44)
    }
    
    centerButton.snp.makeConstraints { make in
      make.centerX.equalTo(tabBarView)
      make.centerY.equalTo(tabBarView.snp.top)
      make.width.height.equalTo(60)
    }
  }
  
  // MARK: - Actions
  private func setupActions() {
    mapButton.addTarget(self, action: #selector(mapButtonTapped), for: .touchUpInside)
    centerButton.addTarget(self, action: #selector(centerButtonTapped), for: .touchUpInside)
    myPageButton.addTarget(self, action: #selector(myPageButtonTapped), for: .touchUpInside)
  }
  
  @objc private func mapButtonTapped() {
    switchToTab(.map)
  }
  
  @objc private func centerButtonTapped() {
    switchToTab(.aiChat)
  }
  
  @objc private func myPageButtonTapped() {
    switchToTab(.myPage)
  }
}

extension TabBarController {
  // MARK: - Tab Switching
  private func switchToTab(_ tab: TabItems) {
    // 이미 선택된 탭이면 아무것도 하지 않음 (두 번 탭했을 때 재생성 방지)
    if selectedTab == tab && currentViewController != nil {
      return
    }
    
    // Update selected state
    mapButton.tintColor = tab == .map ? .systemBlue : .systemGray
    centerButton.backgroundColor = tab == .aiChat ? .systemBlue : .systemGray
    myPageButton.tintColor = tab == .myPage ? .systemBlue : .systemGray
    
    // Remove current view controller from view
    currentViewController?.willMove(toParent: nil)
    currentViewController?.view.removeFromSuperview()
    currentViewController?.removeFromParent()
    
    // 저장된 뷰 컨트롤러가 있는지 확인
    let viewController: UIViewController
    
    if let cachedViewController = viewControllers[tab] {
      // 이미 생성된 뷰 컨트롤러 사용
      viewController = cachedViewController
    } else {
      // 새로운 뷰 컨트롤러 생성 및 저장
      viewController = tab.viewController
      viewControllers[tab] = viewController
    }
    
    addChild(viewController)

    view.insertSubview(viewController.view, belowSubview: tabBarView)
    
    viewController.view.snp.makeConstraints { make in
      make.top.leading.trailing.equalToSuperview()
      make.bottom.equalTo(tabBarView.snp.top)
    }
    
    viewController.didMove(toParent: self)
    currentViewController = viewController
    selectedTab = tab
  }
}
