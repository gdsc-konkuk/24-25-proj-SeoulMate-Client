//
//  KeychainManager.swift
//  SeoulMate
//
//  Created by 박성근 on 5/3/25.
//

import Foundation
import Security

final class KeychainManager {
  static let shared = KeychainManager()
  
  private init() {}
  
  enum KeychainError: Error {
    case noPassword
    case unexpectedPasswordData
    case unhandledError(status: OSStatus)
  }
  
  func save(_ data: Data, service: String, account: String) throws {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecValueData as String: data
    ]
    
    // 기존 항목이 있으면 삭제
    SecItemDelete(query as CFDictionary)
    
    // 새 항목 저장
    let status = SecItemAdd(query as CFDictionary, nil)
    
    guard status == errSecSuccess else {
      throw KeychainError.unhandledError(status: status)
    }
  }
  
  func read(service: String, account: String) throws -> Data {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecReturnData as String: kCFBooleanTrue!,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]
    
    var dataTypeRef: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
    
    guard status == errSecSuccess else {
      throw KeychainError.unhandledError(status: status)
    }
    
    guard let data = dataTypeRef as? Data else {
      throw KeychainError.unexpectedPasswordData
    }
    
    return data
  }
  
  func delete(service: String, account: String) throws {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account
    ]
    
    let status = SecItemDelete(query as CFDictionary)
    
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw KeychainError.unhandledError(status: status)
    }
  }
}
