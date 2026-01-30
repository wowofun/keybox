import Foundation
import CryptoKit

class EncryptionManager {
    static let shared = EncryptionManager()
    
    // Using a hardcoded key for demonstration.
    // In production, this should be derived from user password or stored in Keychain.
    private let keyData: SymmetricKey
    
    private init() {
        // Generate a deterministic key for this app instance
        // WARNING: If app is reinstalled, data might be unrecoverable if key logic changes
        // Best practice: Use Keychain to store a random key
        let keyString = "KeyboxAppSecretKey2024SecureStorage" // 32 chars for AES-256
        let data = keyString.data(using: .utf8)!
        let hash = SHA256.hash(data: data)
        self.keyData = SymmetricKey(data: hash)
    }
    
    func encrypt(_ data: Data) -> Data? {
        do {
            let sealedBox = try AES.GCM.seal(data, using: keyData)
            return sealedBox.combined
        } catch {
            print("Encryption error: \(error)")
            return nil
        }
    }
    
    func decrypt(_ data: Data) -> Data? {
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let decryptedData = try AES.GCM.open(sealedBox, using: keyData)
            return decryptedData
        } catch {
            print("Decryption error: \(error)")
            return nil
        }
    }
}
