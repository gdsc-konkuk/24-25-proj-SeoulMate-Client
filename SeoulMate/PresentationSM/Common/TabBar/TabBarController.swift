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
  
  func viewController(appDIContainer: AppDIContainer) -> UIViewController {
    switch self {
    case .map:
      let mapSceneDIContainer = appDIContainer.makeMapSceneDIContainer()
      let vc = mapSceneDIContainer.makeMapViewController()
      return UINavigationController(rootViewController: vc)
    case .aiChat:
      let aiChatSceneDIContainer = appDIContainer.makeAIChatSceneDIContainer()
      let vc = aiChatSceneDIContainer.makeAIChatViewController()
      return vc
    case .myPage:
      let myPageSceneDIContainer = appDIContainer.makeMyPageSceneDIContainer()
      let vc = myPageSceneDIContainer.makeMyPageViewController()
      return UINavigationController(rootViewController: vc)
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

final class TabBarController: UIViewController {
  
  // MARK: - Properties
  let appDIContainer: AppDIContainer
  
  init(appDIContainer: AppDIContainer) {
    self.appDIContainer = appDIContainer
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private var selectedTab: TabItems = .map
  private var currentViewController: UIViewController?
  private var viewControllers: [TabItems: UIViewController] = [:]
  private var tabBarHeightConstraint: Constraint?
  private let backgroundImageView = UIImageView()
  
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
  
  private lazy var mapTabItem: TabItemView = {
    let view = TabItemView(icon: "Map", title: "Map")
    view.isSelected = true
    return view
  }()
  
  private lazy var myPageTabItem: TabItemView = {
    let view = TabItemView(icon: "MyPage", title: "My Page")
    return view
  }()
  
  private let centerButton: UIButton = {
    let button = UIButton()
    button.backgroundColor = .main500
    button.tintColor = .white
    button.layer.cornerRadius = 37.5
    
    let image = UIImage(systemName: "circle.fill")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 31))
    button.setImage(image, for: .normal)
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
    
    // Add background image view
    view.addSubview(backgroundImageView)
    backgroundImageView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
    
    // Add TabBar View
    view.addSubview(tabBarView)
    tabBarView.snp.makeConstraints { make in
      make.leading.trailing.bottom.equalToSuperview()
      tabBarHeightConstraint = make.height.equalTo(87).constraint
    }
    
    // Add buttons to tabBar
    tabBarView.addSubview(mapTabItem)
    tabBarView.addSubview(myPageTabItem)
    view.addSubview(centerButton)
    
    mapTabItem.snp.makeConstraints { make in
      make.leading.equalTo(tabBarView).offset(50)
      make.top.equalTo(tabBarView).offset(6)
      make.height.equalTo(50)
    }
    
    myPageTabItem.snp.makeConstraints { make in
      make.trailing.equalTo(tabBarView).offset(-50)
      make.top.equalTo(tabBarView).offset(6)
      make.height.equalTo(50)
    }
    
    centerButton.snp.makeConstraints { make in
      make.centerX.equalTo(tabBarView)
      make.centerY.equalTo(tabBarView.snp.top).offset(13)
      make.width.height.equalTo(75)
    }
  }
  
  // MARK: - Actions
  private func setupActions() {
    let mapTapGesture = UITapGestureRecognizer(target: self, action: #selector(mapTabTapped))
    mapTabItem.addGestureRecognizer(mapTapGesture)
    
    let myPageTapGesture = UITapGestureRecognizer(target: self, action: #selector(myPageTabTapped))
    myPageTabItem.addGestureRecognizer(myPageTapGesture)
    
    centerButton.addTarget(self, action: #selector(centerButtonTapped), for: .touchUpInside)
  }
  
  @objc private func mapTabTapped() {
    switchToTab(.map)
  }
  
  @objc private func centerButtonTapped() {
    switchToTab(.aiChat)
  }
  
  @objc private func myPageTabTapped() {
    switchToTab(.myPage)
  }
}

extension TabBarController {
  // MARK: - Tab Switching
  func switchToTab(_ tab: TabItems) {
    // 이미 선택된 탭이면 아무것도 하지 않음 (두 번 탭했을 때 재생성 방지)
    if selectedTab == tab && currentViewController != nil {
      return
    }
    
    // Update selected state
    mapTabItem.isSelected = (tab == .map)
    myPageTabItem.isSelected = (tab == .myPage)
    
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
      viewController = tab.viewController(appDIContainer: appDIContainer)
      viewControllers[tab] = viewController
    }
    
    if tab == .aiChat {
      // Capture current screen
      let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
      let image = renderer.image { context in
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: false)
      }
      backgroundImageView.image = image
      backgroundImageView.isHidden = false
      
      tabBarHeightConstraint?.update(offset: 0)
      centerButton.isHidden = true
      viewController.view.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
      self.view.insertSubview(viewController.view, belowSubview: tabBarView)
      viewController.view.snp.makeConstraints { make in
        make.top.leading.trailing.equalToSuperview()
        make.bottom.equalTo(tabBarView.snp.top)
      }
      addChild(viewController)
      viewController.didMove(toParent: self)
      UIView.animate(withDuration: 0.3) {
        viewController.view.transform = .identity
      }
      currentViewController = viewController
      selectedTab = tab
      return
    }
    
    backgroundImageView.isHidden = true
    tabBarView.isHidden = false
    tabBarHeightConstraint?.update(offset: 87)
    centerButton.isHidden = false
    
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
