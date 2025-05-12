//
//  File.swift
//  SeoulMate
//
//  Created by 박성근 on 5/12/25.
//

import Foundation

final class AIChatSceneDIContainer {
  private let appDIContainer: AppDIContainer
  
  init(appDIContainer: AppDIContainer) {
    self.appDIContainer = appDIContainer
  }
  
  func makeAIChatViewController() -> AIChatViewController {
    return AIChatViewController(useCase: appDIContainer.chatUseCase)
  }
}
