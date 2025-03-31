//
//  KeychainTokenStorage.swift
//  SeoulMate
//
//  Created by 박성근 on 3/31/25.
//

import Foundation
import Security

final class KeychainTokenStorage: TokenStorageProtocol {
    
    private enum KeychainKeys: String {
        case accessToken = "com.seoulmate.accessToken"
        case refreshToken = "com.seoulmate.refreshToken"
        case userId = "com.seoulmate.userId"
        case tokenExpiration = "com.seoulmate.tokenExpiration"
    }
    
  func saveTokens(
    accessToken: String,
    refreshToken: String,
    userId: String,
    expiresIn: Int
  ) {
        save(key: KeychainKeys.accessToken.rawValue, value: accessToken)
        save(key: KeychainKeys.refreshToken.rawValue, value: refreshToken)
        save(key: KeychainKeys.userId.rawValue, value: userId)
        
        let expirationDate = Date().addingTimeInterval(TimeInterval(expiresIn))
        if let expirationData = try? JSONEncoder().encode(expirationDate) {
            save(key: KeychainKeys.tokenExpiration.rawValue, value: String(data: expirationData, encoding: .utf8) ?? "")
        }
    }
    
    func getAccessToken() -> String? {
        return load(key: KeychainKeys.accessToken.rawValue)
    }
    
    func getRefreshToken() -> String? {
        return load(key: KeychainKeys.refreshToken.rawValue)
    }
    
    func getUserId() -> String? {
        return load(key: KeychainKeys.userId.rawValue)
    }
    
    func getTokenExpiration() -> Date? {
        guard let expirationString = load(key: KeychainKeys.tokenExpiration.rawValue),
              let expirationData = expirationString.data(using: .utf8) else {
            return nil
        }
        
        return try? JSONDecoder().decode(Date.self, from: expirationData)
    }
    
    func isTokenValid() -> Bool {
        guard let expirationDate = getTokenExpiration(),
              let accessToken = getAccessToken() else {
            return false
        }
        
        return !accessToken.isEmpty && expirationDate > Date()
    }
    
    func clearTokens() {
        delete(key: KeychainKeys.accessToken.rawValue)
        delete(key: KeychainKeys.refreshToken.rawValue)
        delete(key: KeychainKeys.userId.rawValue)
        delete(key: KeychainKeys.tokenExpiration.rawValue)
    }
    
    // MARK: - Private Keychain Methods
    
    private func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete existing item if exists
        SecItemDelete(query as CFDictionary)
        
        // Add the new item
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue as Any,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            if let retrievedData = dataTypeRef as? Data,
               let value = String(data: retrievedData, encoding: .utf8) {
                return value
            }
        }
        
        return nil
    }
    
    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
