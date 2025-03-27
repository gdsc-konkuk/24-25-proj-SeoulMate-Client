//
//  SceneDelegate.swift
//  SeoulMate
//
//  Created by 박성근 on 3/27/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  
  var window: UIWindow?
  
  
  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else {return}
    self.window = UIWindow(windowScene: windowScene)
    
    let rootViewController = TabBarController() // Change to Root View
    let rootNavigationController = UINavigationController(rootViewController: rootViewController)
    
    self.window?.rootViewController = rootNavigationController
    self.window?.makeKeyAndVisible()
  }
  
  func sceneDidDisconnect(_ scene: UIScene) {
    
  }
  
  func sceneDidBecomeActive(_ scene: UIScene) {
    
  }
  
  func sceneWillResignActive(_ scene: UIScene) {
    
  }
  
  func sceneWillEnterForeground(_ scene: UIScene) {
    
  }
  
  func sceneDidEnterBackground(_ scene: UIScene) {
    
  }
  
  
}

