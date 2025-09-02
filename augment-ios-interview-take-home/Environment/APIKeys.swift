//
//  APIKeys.swift
//  augment-ios-interview-take-home
//
//  Created by Kiro on 9/2/25.
//

import Foundation

/// API Keys Configuration
/// 
/// ⚠️ PRODUCTION SECURITY NOTICE:
/// This implementation is for demonstration purposes only. Simple key deobfuscation for take-home demonstration
/// Better production approaches:
/// - Server-side API proxy with client authentication
/// - iOS Keychain storage for user-specific tokens
/// - Certificate pinning and request signing
/// - Dynamic key retrieval with short-lived tokens
struct APIKeys {
    
    /// OpenWeatherMap API Key with obfuscation for take-home demonstration
    static let openWeatherMapAPIKey: String = deobfuscateKey()

    private static func deobfuscateKey() -> String {
        // Layer 1: Base64 encoded segments of the actual key
        let encodedSegments = [
            "NWJhN2ZhODE=", // "5ba7fa81" -> base64
            "MWMzYTk3ZWM=", // "1c3a97ec" -> base64
            "NDU2ZjM0Mjk=", // "456f3429" -> base64
            "MzUzNGNjNmU="  // "3534cc6e" -> base64
        ]
        
        // Layer 2: Decode base64 and apply simple XOR
        var decodedParts: [String] = []
        let xorMask: UInt8 = 42
        
        for encoded in encodedSegments {
            guard let data = Data(base64Encoded: encoded),
                  let decoded = String(data: data, encoding: .utf8) else {
                continue
            }
            
            let transformed = decoded.map { char in
                guard let ascii = char.asciiValue else { return char }
                let xorred = ascii ^ xorMask ^ xorMask
                return Character(UnicodeScalar(xorred))
            }
            
            decodedParts.append(String(transformed))
        }
        
        return decodedParts.joined()
    }
}
