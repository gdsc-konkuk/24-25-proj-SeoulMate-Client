//
//  DIContainer.swift
//  SeoulMate
//
//  Created by 박성근 on 4/1/25.
//

import OSLog
import GooglePlaces

public typealias DependencyContainerClosure = (DIContainable) -> Any

public protocol DIContainable {
  func register<T>(type: T.Type, containerClosure: @escaping DependencyContainerClosure)
  func resolve<T>(type: T.Type) -> T?
}

public final class DIContainer: DIContainable {
  public static let shared: DIContainer = DIContainer()
  
  var services: [String: DependencyContainerClosure] = [:]
  
  private init() {}
  
  public func register<T>(type: T.Type, containerClosure: @escaping DependencyContainerClosure) {
    services["\(type)"] = containerClosure
  }
  
  public func resolve<T>(type: T.Type) -> T? {
    let service = services["\(type)"]?(self) as? T
    
    if service == nil {
      Logger.log(message: "\(#file) - \(#line): \(#function) - \(type) resolve error")
    }
    
    return service
  }
}

extension DIContainer {
  // GoogleAuth
  func registerAuthDependencies() {
    // TokenStorage
    register(type: TokenStorageProtocol.self) { _ in
      return KeychainTokenStorage()
    }
    
    // AuthRepository
    register(type: AuthRepositoryProtocol.self) { container in
      let networkService = container.resolve(type: NetworkServiceProtocol.self)!
      // Config.xcconfig에서 설정한 BASE_URL
      let baseURL = Bundle.main.infoDictionary?["BASE_URL"] as? String ?? "https://api.seoulmate.com"
      return AuthRepository(networkService: networkService, baseURL: baseURL)
    }
    
    // LoginUseCase
    register(type: LoginUseCaseProtocol.self) { container in
      let authRepository = container.resolve(type: AuthRepositoryProtocol.self)!
      let tokenStorage = container.resolve(type: TokenStorageProtocol.self)!
      return LoginUseCase(authRepository: authRepository, tokenStorage: tokenStorage)
    }
    
    // GoogleAuthService
    register(type: GoogleAuthServiceProtocol.self) { _ in
      return GoogleAuthService()
    }
  }
  
  // NetworkService
  func registerNetworkDependencies() {
    // NetworkService
    register(type: NetworkServiceProtocol.self) { container in
      let tokenStorage = container.resolve(type: TokenStorageProtocol.self)!
      return NetworkService(tokenStorage: tokenStorage)
    }
  }
  
  // PlacesAPI
  func registerPlacesDependencies() {
    // Google Places 네트워크 서비스
    register(type: GooglePlacesNetworkServiceProtocol.self) { _ in
      return GooglePlacesNetworkService(placesClient: GMSPlacesClient.shared())
    }
    
    // Place 이미지 처리를 위한 Service 등록
    register(type: PlacesServiceProtocol.self) { _ in
      return PlacesService(placesClient: GMSPlacesClient.shared())
    }
    
    // PlaceImage 네트워크 서비스 등록
    register(type: GooglePlaceImageNetworkServiceProtocol.self) { container in
      let networkService = container.resolve(type: NetworkServiceProtocol.self)!
      let placesService = container.resolve(type: PlacesServiceProtocol.self)!
      return GooglePlaceImageNetworkService(networkService: networkService, placesService: placesService)
    }
    
    // PlaceImage 리포지토리 등록
    register(type: PlaceImageRepositoryProtocol.self) { container in
      let networkService = container.resolve(type: GooglePlaceImageNetworkServiceProtocol.self)!
      return PlaceImageRepository(networkService: networkService)
    }
    
    // 통합된 Places Repository
    register(type: PlacesRepositoryProtocol.self) { container in
      let networkService = container.resolve(type: GooglePlacesNetworkServiceProtocol.self)!
      let imageNetworkService = container.resolve(type: GooglePlaceImageNetworkServiceProtocol.self)!
      return PlacesRepository(networkService: networkService, imageNetworkService: imageNetworkService)
    }
    
    // Places 관련 UseCase들
    register(type: PlaceSearchUseCaseProtocol.self) { container in
      let repository = container.resolve(type: PlacesRepositoryProtocol.self)!
      return PlaceSearchUseCase(repository: repository)
    }
    
    register(type: FetchPlaceImagesUseCaseProtocol.self) { container in
      let repository = container.resolve(type: PlaceImageRepositoryProtocol.self)!
      return FetchPlaceImagesUseCase(repository: repository)
    }
  }
}
