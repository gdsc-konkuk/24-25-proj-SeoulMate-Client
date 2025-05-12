//
//  LoginSceneDIContainer.swift
//  SeoulMate
//
//  Created by 박성근 on 5/12/25.
//

import Foundation

final class LoginSceneDIContainer {
  private let appDIContainer: AppDIContainer
  
  init(appDIContainer: AppDIContainer) {
    self.appDIContainer = appDIContainer
  }
  
  func makeSocialLoginViewController() -> SocialLoginViewController {
    return SocialLoginViewController(
      loginUseCase: appDIContainer.loginUseCase
    )
  }
  
  func makeTravelWithViewController() -> TravelWithViewController {
    return TravelWithViewController()
  }
  
  func makeTravelPurposeViewController(travelCompanion: String) -> TravelPurposeViewController {
    return TravelPurposeViewController(
      travelCompanion: travelCompanion,
      updateUserProfileUseCase: appDIContainer.updateUserProfileUseCase
    )
  }
}
