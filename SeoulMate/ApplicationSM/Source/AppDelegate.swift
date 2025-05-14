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
    // Force English language for the app
    UserDefaults.standard.set(["en"], forKey: "AppleLanguages")
    UserDefaults.standard.synchronize()
    
    // Maps, Places
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAP_API_KEY") as? String {
      GMSServices.provideAPIKey(apiKey)
      GMSPlacesClient.provideAPIKey(apiKey)
    } else {
      // TODO: Alert
      Logger.log("Error: Google Map Api Key 설정 안됨")
    }
    
    if let clientID = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_LOGIN_CLIENT_ID") as? String {
      // Google Sign-In 설정
      let clientIDWithDomain = clientID.hasSuffix(".apps.googleusercontent.com") ? clientID : "\(clientID).apps.googleusercontent.com"
      GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientIDWithDomain)
    } else {
      print("ERROR: Google Login Client ID가 Info.plist에 설정되지 않았습니다")
      // TODO: Alert
      Logger.log("ERROR: Google Login Client ID가 Info.plist에 설정되지 않았습니다")
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
