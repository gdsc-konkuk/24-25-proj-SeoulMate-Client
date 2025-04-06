//
//  AppDelegate.swift
//  SeoulMate
//
//  Created by 박성근 on 3/27/25.
//

import UIKit
import GoogleMaps
import GooglePlaces
import GoogleSignIn

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Maps, Places
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAP_API_KEY") as? String {
      GMSServices.provideAPIKey(apiKey)
      GMSPlacesClient.provideAPIKey(apiKey)
    } else {
      // TODO: Alert
    }
    
    GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
      if let error = error {
        // TODO: Alert
      } else if let user = user {
        print("사용자 \(user.profile?.email ?? "알 수 없음") 로그인 상태 복원됨")
        NotificationCenter.default.post(name: Notification.Name.userDidSignIn, object: nil)
      }
    }
    return true
  }
  
  func application(
    _ app: UIApplication,
    open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    var handled: Bool
    
    handled = GIDSignIn.sharedInstance.handle(url)
    if handled {
      return true
    }
    
    // Handle other custom URL types.
    
    // If not handled by this app, return false.
    return false
  }
  
  // MARK: UISceneSession Lifecycle
  func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    
    return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }
  
  func application(
    _ application: UIApplication,
    didDiscardSceneSessions sceneSessions: Set<UISceneSession>
  ) {
    
  }
}

