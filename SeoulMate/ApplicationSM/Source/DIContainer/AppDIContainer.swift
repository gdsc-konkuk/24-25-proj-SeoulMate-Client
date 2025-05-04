//
//  AppDIContainer.swift
//  SeoulMate
//
//  Created by 박성근 on 5/4/25.
//

import Foundation

final class AppDIContainer {
  
  // MARK: - Network
  lazy var networkProvider: NetworkProviderProtocol = {
    let interceptor = NetworkInterceptor()
    let logger = NetworkLogger()
    return NetworkProvider(
      interceptor: interceptor,
      eventMonitors: [logger]
    )
  }()
  
  // MARK: - Services
  lazy var authService: AuthServiceProtocol = {
    return AuthService(networkProvider: networkProvider)
  }()
  
  lazy var userService: UserServiceProtocol = {
    return UserService(networkProvider: networkProvider)
  }()
  
  lazy var placeService: PlaceServiceProtocol = {
    return PlaceService(networkProvider: networkProvider)
  }()
  
  // TODO: AIChatService will be implemented later
  
  // MARK: - Repositories
  lazy var authRepository: AuthRepositoryProtocol = {
    return AuthRepository(authService: authService)
  }()
  
  lazy var userRepository: UserRepositoryProtocol = {
    return UserRepository(userService: userService)
  }()
  
  lazy var placeRepository: PlaceRepositoryProtocol = {
    return PlaceRepository(placeService: placeService)
  }()
  
  lazy var filterRepository: FilterRepositoryProtocol = {
    return FilterRepository(userService: userService)
  }()
  
  // MARK: - Use Cases
  // Auth Use Cases
  lazy var loginUseCase: LoginUseCaseProtocol = {
    return LoginUseCase(authRepository: authRepository)
  }()
  
  lazy var refreshTokenUseCase: RefreshTokenUseCaseProtocol = {
    return RefreshTokenUseCase(authRepository: authRepository)
  }()
  
  // User Use Cases
  lazy var getUserProfileUseCase: GetUserProfileUseCaseProtocol = {
    return GetUserProfileUseCase(userRepository: userRepository)
  }()
  
  lazy var updateUserProfileUseCase: UpdateUserProfileUseCaseProtocol = {
    return UpdateUserProfileUseCase(userRepository: userRepository)
  }()
  
  lazy var getUserHistoriesUseCase: GetUserHistoriesUseCaseProtocol = {
    return GetUserHistoriesUseCase(userRepository: userRepository)
  }()
  
  // Place Use Cases
  lazy var getRecommendedPlacesUseCase: GetRecommendedPlacesUseCaseProtocol = {
    return GetRecommendedPlacesUseCase(placeRepository: placeRepository)
  }()
  
  lazy var generatePlacePromptUseCase: GeneratePlacePromptUseCaseProtocol = {
    return GeneratePlacePromptUseCase(placeRepository: placeRepository)
  }()
  
  // MARK: - Scene DIContainers
  func makeLoginSceneDIContainer() -> LoginSceneDIContainer {
    return LoginSceneDIContainer(appDIContainer: self)
  }
  
  func makeMapSceneDIContainer() -> MapSceneDIContainer {
    return MapSceneDIContainer(appDIContainer: self)
  }
  
  func makeMyPageSceneDIContainer() -> MyPageSceneDIContainer {
    return MyPageSceneDIContainer(appDIContainer: self)
  }
  
  func makeAIChatSceneDIContainer() -> AIChatSceneDIContainer {
    return AIChatSceneDIContainer(appDIContainer: self)
  }
  
  // MARK: - TabBar
  func makeTabBarController() -> TabBarController {
    return TabBarController(appDIContainer: self)
  }
}

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

final class MapSceneDIContainer {
  private let appDIContainer: AppDIContainer
  
  init(appDIContainer: AppDIContainer) {
    self.appDIContainer = appDIContainer
  }
  
  func makeMapViewController() -> MapViewController {
    return MapViewController(
      appDIContainer: appDIContainer,  // AppDIContainer 전달
      getRecommendedPlacesUseCase: appDIContainer.getRecommendedPlacesUseCase,
      generatePlacePromptUseCase: appDIContainer.generatePlacePromptUseCase
    )
  }
  
  func makeFilterViewController() -> FilterViewController {
    return FilterViewController(
      getUserProfileUseCase: appDIContainer.getUserProfileUseCase,
      updateUserProfileUseCase: appDIContainer.updateUserProfileUseCase
    )
  }
}

final class MyPageSceneDIContainer {
  private let appDIContainer: AppDIContainer
  
  init(appDIContainer: AppDIContainer) {
    self.appDIContainer = appDIContainer
  }
  
  func makeMyPageViewController() -> MyPageViewController {
    return MyPageViewController()
  }
}

final class AIChatSceneDIContainer {
  private let appDIContainer: AppDIContainer
  
  init(appDIContainer: AppDIContainer) {
    self.appDIContainer = appDIContainer
  }
  
  func makeAIChatViewController() -> AIChatViewController {
    return AIChatViewController()
  }
}
