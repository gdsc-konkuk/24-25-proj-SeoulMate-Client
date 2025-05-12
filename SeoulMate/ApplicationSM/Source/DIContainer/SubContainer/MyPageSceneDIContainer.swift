//
//  File.swift
//  SeoulMate
//
//  Created by 박성근 on 5/12/25.
//

import Foundation

final class MyPageSceneDIContainer {
  private let appDIContainer: AppDIContainer
  
  init(appDIContainer: AppDIContainer) {
    self.appDIContainer = appDIContainer
  }
  
  func makeMyPageViewController() -> MyPageViewController {
    return MyPageViewController(
      appDIContainer: appDIContainer,
      getLikedPlacesUseCase: appDIContainer.getLikedPlacesUseCase
    )
  }
}

