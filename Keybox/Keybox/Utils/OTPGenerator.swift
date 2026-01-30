import Foundation
import CryptoKit

struct OTPGenerator {
    
    static func generateTOTP(secret: String, timeInterval: TimeInterval = 30, digits: Int = 6) -> String? {
        guard let data = Base32.decode(string: secret) else { return nil }
        
        let timeIntervalSince1970 = Date().timeIntervalSince1970
        let counter = UInt64(timeIntervalSince1970 / timeInterval)
        let counterBigEndian = counter.bigEndian
        
        let counterData = Data(bytes: [counterBigEndian], count: MemoryLayout<UInt64>.size)
        
        // HMAC-SHA1 (Standard for TOTP)
        let key = SymmetricKey(data: data)
        let signature = HMAC<Insecure.SHA1>.authenticationCode(for: counterData, using: key)
        
        var truncatedHash: UInt32 = 0
        signature.withUnsafeBytes { ptr in
            let offset = Int(ptr[ptr.count - 1] & 0x0f)
            
            // Safely read 4 bytes
            let byte0 = UInt32(ptr[offset])
            let byte1 = UInt32(ptr[offset + 1])
            let byte2 = UInt32(ptr[offset + 2])
            let byte3 = UInt32(ptr[offset + 3])
            
            // RFC 4226: "The dynamic binary code will be the 31-bit, unsigned, big-endian integer..."
            // We constructed a Big Endian integer (byte0 is MSB).
            // However, typical implementations (like Google Authenticator) treat the hash as a byte array,
            // pick 4 bytes, and treat them as a Big Endian integer.
            // Our construction: (byte0 << 24) | ... DOES create that integer value correctly.
            // So 'trunk' IS the Big Endian value.
            
            truncatedHash = ((byte0 << 24) | (byte1 << 16) | (byte2 << 8) | byte3) & 0x7fffffff
        }
        
        let pinValue = truncatedHash % UInt32(pow(10, Float(digits)))
        return String(format: "%0*u", digits, pinValue)
    }
    
    static func generateHOTP(secret: String, counter: UInt64, digits: Int = 6) -> String? {
        guard let data = Base32.decode(string: secret) else { return nil }
        
        let counterBigEndian = counter.bigEndian
        let counterData = Data(bytes: [counterBigEndian], count: MemoryLayout<UInt64>.size)
        
        let key = SymmetricKey(data: data)
        let signature = HMAC<Insecure.SHA1>.authenticationCode(for: counterData, using: key)
        
        var truncatedHash: UInt32 = 0
        signature.withUnsafeBytes { ptr in
            let offset = Int(ptr[ptr.count - 1] & 0x0f)
            
            // Safely read 4 bytes
            let byte0 = UInt32(ptr[offset])
            let byte1 = UInt32(ptr[offset + 1])
            let byte2 = UInt32(ptr[offset + 2])
            let byte3 = UInt32(ptr[offset + 3])
            
            truncatedHash = ((byte0 << 24) | (byte1 << 16) | (byte2 << 8) | byte3) & 0x7fffffff
        }
        
        let pinValue = truncatedHash % UInt32(pow(10, Float(digits)))
        return String(format: "%0*u", digits, pinValue)
    }
    
    static func generateRandomSecret(length: Int = 16) -> String {
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        return String((0..<length).map { _ in alphabet.randomElement()! })
    }
}

// Simple Base32 Decoder
struct Base32 {
    private static let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
    
    static func decode(string: String) -> Data? {
        let lookup = alphabet.enumerated().reduce(into: [Character: Int]()) { $0[$1.element] = $1.offset }
        
        var buffer = 0
        var bitsLeft = 0
        var data = Data()
        
        for char in string.uppercased() where char != "=" && char != " " {
            guard let val = lookup[char] else { return nil }
            
            buffer = (buffer << 5) | val
            bitsLeft += 5
            
            if bitsLeft >= 8 {
                let byte = UInt8((buffer >> (bitsLeft - 8)) & 0xFF)
                data.append(byte)
                bitsLeft -= 8
            }
        }
        
        return data
    }
}
