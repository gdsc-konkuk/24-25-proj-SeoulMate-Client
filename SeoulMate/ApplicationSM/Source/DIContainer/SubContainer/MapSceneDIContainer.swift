//
//  MapSceneDIContainer.swift
//  SeoulMate
//
//  Created by 박성근 on 5/12/25.
//

import Foundation

final class MapSceneDIContainer {
  private let appDIContainer: AppDIContainer
  
  init(appDIContainer: AppDIContainer) {
    self.appDIContainer = appDIContainer
  }
  
  func makeMapViewController() -> MapViewController {
    return MapViewController(
      appDIContainer: appDIContainer,  // AppDIContainer 전달
      getRecommendedPlacesUseCase: appDIContainer.getRecommendedPlacesUseCase,
      getUserProfileUseCase: appDIContainer.getUserProfileUseCase,
      getLikedPlacesUseCase: appDIContainer.getLikedPlacesUseCase
    )
  }
  
  func makeFilterViewController() -> FilterViewController {
    return FilterViewController(
      getUserProfileUseCase: appDIContainer.getUserProfileUseCase,
      updateUserProfileUseCase: appDIContainer.updateUserProfileUseCase
    )
  }
  
  func makePlaceDetailViewController(placeId: String) -> PlaceDetailViewController {
    return PlaceDetailViewController(
      placeId: placeId,
      updateLikeStatusUseCase: appDIContainer.updateLikeStatusUseCase
    )
  }
}
