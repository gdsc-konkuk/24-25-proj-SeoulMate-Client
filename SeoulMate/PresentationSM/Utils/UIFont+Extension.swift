//
//  UIFont+Extension.swift
//  SeoulMate
//
//  Created by 박성근 on 4/7/25.
//

import UIKit

extension UIFont {
  enum CustomFont: String {
    case light = "SF-Pro-Display-Light"
    case regular = "SF-Pro-Display-Regular"
    case medium = "SF-Pro-Display-Medium"
    case bold = "SF-Pro-Display-Bold"
  }
  
  static func lightFont(
    ofSize size: CGFloat
  ) -> UIFont {
    return custom(.light, size: size)
  }
  
  static func regularFont(
    ofSize size: CGFloat
  ) -> UIFont {
    return custom(.regular, size: size)
  }
  
  static func mediumFont(
    ofSize size: CGFloat
  ) -> UIFont {
    return custom(.medium, size: size)
  }
  
  static func boldFont(
    ofSize size: CGFloat
  ) -> UIFont {
    return custom(.bold, size: size)
  }
  
  private static func custom(
    _ font: CustomFont,
    size: CGFloat
  ) -> UIFont {
    return UIFont(name: font.rawValue, size: size) ?? UIFont.systemFont(ofSize: size)
  }
}
