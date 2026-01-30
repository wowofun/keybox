import Foundation
import Combine

struct DeletedToken: Codable, Identifiable {
    var id: UUID = UUID()
    let originalToken: OTPToken
    let deletedDate: Date
}

struct DeletedAccount: Codable, Identifiable {
    var id: UUID = UUID()
    let originalAccount: Account
    let deletedDate: Date
}

class TrashManager: ObservableObject {
    static let shared = TrashManager()
    
    @Published var deletedTokens: [DeletedToken] = []
    @Published var deletedAccounts: [DeletedAccount] = []
    
    private let saveKeyTokens = "trash_tokens_v1"
    private let saveKeyAccounts = "trash_accounts_v1"
    
    init() {
        loadTrash()
    }
    
    // MARK: - Tokens
    
    @discardableResult
    func moveToTrash(_ token: OTPToken) -> UUID {
        let deletedItem = DeletedToken(originalToken: token, deletedDate: Date())
        deletedTokens.append(deletedItem)
        saveTrash()
        return deletedItem.id
    }
    
    func restoreToken(id: UUID) -> OTPToken? {
        if let index = deletedTokens.firstIndex(where: { $0.id == id }) {
            let token = deletedTokens[index].originalToken
            deletedTokens.remove(at: index)
            saveTrash()
            return token
        }
        return nil
    }
    
    func getDeletedToken(by id: UUID) -> DeletedToken? {
        return deletedTokens.first(where: { $0.id == id })
    }
    
    // MARK: - Accounts
    
    @discardableResult
    func moveToTrash(_ account: Account) -> UUID {
        let deletedItem = DeletedAccount(originalAccount: account, deletedDate: Date())
        deletedAccounts.append(deletedItem)
        saveTrash()
        return deletedItem.id
    }
    
    func restoreAccount(id: UUID) -> Account? {
        if let index = deletedAccounts.firstIndex(where: { $0.id == id }) {
            let account = deletedAccounts[index].originalAccount
            deletedAccounts.remove(at: index)
            saveTrash()
            return account
        }
        return nil
    }
    
    func getDeletedAccount(by id: UUID) -> DeletedAccount? {
        return deletedAccounts.first(where: { $0.id == id })
    }
    
    // MARK: - Persistence
    
    private func saveTrash() {
        // Save Tokens
        if let encodedTokens = try? JSONEncoder().encode(deletedTokens) {
            if let encryptedTokens = EncryptionManager.shared.encrypt(encodedTokens) {
                UserDefaults.standard.set(encryptedTokens, forKey: saveKeyTokens)
            }
        }
        
        // Save Accounts
        if let encodedAccounts = try? JSONEncoder().encode(deletedAccounts) {
            if let encryptedAccounts = EncryptionManager.shared.encrypt(encodedAccounts) {
                UserDefaults.standard.set(encryptedAccounts, forKey: saveKeyAccounts)
            }
        }
    }
    
    private func loadTrash() {
        // Load Tokens
        if let dataTokens = UserDefaults.standard.data(forKey: saveKeyTokens) {
            if let decryptedTokens = EncryptionManager.shared.decrypt(dataTokens),
               let decodedTokens = try? JSONDecoder().decode([DeletedToken].self, from: decryptedTokens) {
                deletedTokens = decodedTokens
            }
        }
        
        // Load Accounts
        if let dataAccounts = UserDefaults.standard.data(forKey: saveKeyAccounts) {
            if let decryptedAccounts = EncryptionManager.shared.decrypt(dataAccounts),
               let decodedAccounts = try? JSONDecoder().decode([DeletedAccount].self, from: decryptedAccounts) {
                deletedAccounts = decodedAccounts
            }
        }
    }
}
