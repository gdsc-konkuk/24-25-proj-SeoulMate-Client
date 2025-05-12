//
//  PaddingTextField.swift
//  SeoulMate
//
//  Created by 박성근 on 5/12/25.
//

import UIKit

// MARK: - Custom PaddedTextField
final class PaddedTextField: UITextField {
  let padding = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
  
  override func textRect(forBounds bounds: CGRect) -> CGRect {
    return bounds.inset(by: padding)
  }
  
  override func editingRect(forBounds bounds: CGRect) -> CGRect {
    return bounds.inset(by: padding)
  }
  
  override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
    return bounds.inset(by: padding)
  }
}
