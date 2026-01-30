import Foundation
import Combine
import SwiftUI

class TokenViewModel: ObservableObject {
    static let shared = TokenViewModel() // Add singleton instance
    
    @Published var tokens: [OTPToken] = []
    @Published var searchText: String = ""
    
    private var timer: AnyCancellable?
    private let saveKey = "saved_tokens_v1"
    
    init() {
        loadTokens()
        startTimer()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleCloudUpdate), name: Notification.Name("DataDidUpdateFromCloud"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleResetData), name: Notification.Name("ResetAllData"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleCloudUpdate() {
        loadTokens()
    }
    
    @objc private func handleResetData() {
        tokens.removeAll()
        saveTokens()
    }
    
    var filteredTokens: [OTPToken] {
        if searchText.isEmpty {
            return tokens
        } else {
            return tokens.filter { $0.issuer.localizedCaseInsensitiveContains(searchText) || $0.accountName.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    func addToken(issuer: String, accountName: String, secret: String) {
        // Clean secret (remove spaces)
        let cleanSecret = secret.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        // Basic validation
        guard !cleanSecret.isEmpty else { return }
        
        let newToken = OTPToken(issuer: issuer, accountName: accountName, secret: cleanSecret)
        tokens.append(newToken)
        saveTokens()
        
        NotificationManager.shared.addNotification(
            type: .add,
            title: "Added Token".localized,
            message: String(format: "Added account".localized, "\(issuer) (\(accountName))")
        )
    }
    
    func deleteToken(at offsets: IndexSet) {
        // Collect info before deletion for notification
        let tokensToDelete = offsets.map { tokens[$0] }
        
        tokens.remove(atOffsets: offsets)
        saveTokens()
        
        for token in tokensToDelete {
            // Move to Trash
            let trashID = TrashManager.shared.moveToTrash(token)
            
            NotificationManager.shared.addNotification(
                type: .delete,
                title: "Deleted Token".localized,
                message: String(format: "Deleted account".localized, "\(token.issuer) (\(token.accountName))"),
                associatedID: trashID
            )
        }
    }
    
    func deleteToken(_ token: OTPToken) {
        if let index = tokens.firstIndex(where: { $0.id == token.id }) {
            tokens.remove(at: index)
            saveTokens()
            
            // Move to Trash
            let trashID = TrashManager.shared.moveToTrash(token)
            
            NotificationManager.shared.addNotification(
                type: .delete,
                title: "Deleted Token".localized,
                message: String(format: "Deleted account".localized, "\(token.issuer) (\(token.accountName))"),
                associatedID: trashID
            )
        }
    }
    
    func restoreToken(_ token: OTPToken) {
        if let index = tokens.firstIndex(where: { $0.id == token.id }) {
            // Restore (Overwrite existing)
            tokens[index] = token
            saveTokens()
            
            NotificationManager.shared.addNotification(
                type: .update,
                title: "Restored Token".localized,
                message: String(format: "Restored account".localized, "\(token.issuer) (\(token.accountName))")
            )
        } else {
            // Restore (Add new)
            tokens.append(token)
            saveTokens()
            
            NotificationManager.shared.addNotification(
                type: .add,
                title: "Restored Token".localized,
                message: String(format: "Restored account".localized, "\(token.issuer) (\(token.accountName))")
            )
        }
    }
    
    func updateToken(_ token: OTPToken) {
        if let index = tokens.firstIndex(where: { $0.id == token.id }) {
            // Backup old version
            let oldToken = tokens[index]
            let trashID = TrashManager.shared.moveToTrash(oldToken)
            
            tokens[index] = token
            saveTokens()
            
            NotificationManager.shared.addNotification(
                type: .update,
                title: "Updated Token".localized,
                message: String(format: "Updated account".localized, "\(token.issuer) (\(token.accountName))"),
                associatedID: trashID
            )
        }
    }
    
    private func saveTokens() {
        if let encoded = try? JSONEncoder().encode(tokens) {
            // Encrypt before saving
            if let encrypted = EncryptionManager.shared.encrypt(encoded) {
                UserDefaults.standard.set(encrypted, forKey: saveKey)
                CloudSyncManager.shared.sync()
            }
        }
    }
    
    private func loadTokens() {
        if let data = UserDefaults.standard.data(forKey: saveKey) {
            // Try to decrypt first
            if let decrypted = EncryptionManager.shared.decrypt(data),
               let decoded = try? JSONDecoder().decode([OTPToken].self, from: decrypted) {
                tokens = decoded
            } else if let decoded = try? JSONDecoder().decode([OTPToken].self, from: data) {
                // Fallback for legacy unencrypted data
                tokens = decoded
                // Re-save to encrypt it
                saveTokens()
            }
        } else {
            // Add a demo token if empty
            // Secret: JBSWY3DPEHPK3PXP (Hello world base32)
            // tokens = [OTPToken(issuer: "Keybox Demo", accountName: "demo@keybox.app", secret: "JBSWY3DPEHPK3PXP")]
        }
    }
    
    private func startTimer() {
        // No timer needed - TokenCard uses TimelineView for self-updating
    }
}
