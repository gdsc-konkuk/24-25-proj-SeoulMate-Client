//
//  SocialLoginViewController.swift
//  SeoulMate
//
//  Created by 박성근 on 4/7/25.
//

import UIKit
import SnapKit
import GoogleSignIn
import SwiftUI

final class SocialLoginViewController: UIViewController {
  
  // MARK: - Properties
  private let titleLabel: UILabel = {
    let label = UILabel()
    label.text = "SeoulMate"
    label.font = .boldFont(ofSize: 36)
    label.textAlignment = .center
    return label
  }()
  
  // google login button
  private let googleSignInButton: GIDSignInButton = {
    let button = GIDSignInButton()
    button.style = .wide
    button.colorScheme = .light
    return button
  }()
  
  // MARK: - LifeCycle
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    setupActions()
  }
}

extension SocialLoginViewController {
  private func setupUI() {
    view.backgroundColor = .white
    
    view.addSubview(titleLabel)
    view.addSubview(googleSignInButton)
    
    titleLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(UIApplication.screenHeight * 0.3)
      make.centerX.equalToSuperview()
    }
    
    googleSignInButton.snp.makeConstraints { make in
      make.bottom.equalToSuperview().offset(-UIApplication.screenHeight * 0.15)
      make.centerX.equalToSuperview()
      make.width.equalTo(UIApplication.screenWidth * 0.7)
    }
  }
  
  private func setupActions() {
    googleSignInButton.addTarget(self, action: #selector(handleGoogleSignIn), for: .touchUpInside)
  }
}

extension SocialLoginViewController {
  @objc private func handleGoogleSignIn() {
    GIDSignIn.sharedInstance.signIn(withPresenting: self) { signInResult, error in
      guard error == nil else { return }
      
      // If sign in succeeded, display the app's main content View.
      NotificationCenter.default.post(name: Notification.Name.userDidSignIn, object: nil)
    }
  }
}

struct PreView: PreviewProvider {
    static var previews: some View {
      SocialLoginViewController().toPreview()
    }
}
