//
//  TabBarController.swift
//  SeoulMate
//
//  Created on 3/27/25.
//

import UIKit
import SnapKit

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
    
    // MARK: - UI Components
    private let tabBarView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
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
      // Update selected state
      mapButton.tintColor = tab == .map ? .systemBlue : .systemGray
      centerButton.backgroundColor = tab == .aiChat ? .systemBlue : .systemGray
      myPageButton.tintColor = tab == .myPage ? .systemBlue : .systemGray
      
      // Remove current view controller
      currentViewController?.willMove(toParent: nil)
      currentViewController?.view.removeFromSuperview()
      currentViewController?.removeFromParent()
      
      // Add new view controller
      let newViewController = tab.viewController
      addChild(newViewController)
      
      // Insert below tabBar
      view.insertSubview(newViewController.view, belowSubview: tabBarView)
      
      newViewController.view.snp.makeConstraints { make in
          make.top.leading.trailing.equalToSuperview()
          make.bottom.equalTo(tabBarView.snp.top)
      }
      
      newViewController.didMove(toParent: self)
      currentViewController = newViewController
      selectedTab = tab
  }
}
