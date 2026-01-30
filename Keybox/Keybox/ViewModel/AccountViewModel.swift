import Foundation
import Combine
import SwiftUI

class AccountViewModel: ObservableObject {
    @Published var accounts: [Account] = []
    @Published var searchText: String = ""
    
    private let saveKey = "saved_accounts_v1"
    
    init() {
        loadAccounts()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleCloudUpdate), name: Notification.Name("DataDidUpdateFromCloud"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleResetData), name: Notification.Name("ResetAllData"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleCloudUpdate() {
        loadAccounts()
    }
    
    @objc private func handleResetData() {
        accounts.removeAll()
        saveAccounts()
    }
    
    var filteredAccounts: [Account] {
        if searchText.isEmpty {
            return accounts
        } else {
            return accounts.filter { $0.title.localizedCaseInsensitiveContains(searchText) || $0.account.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    func accounts(for category: AccountCategory?) -> [Account] {
        let list = filteredAccounts
        guard let category = category else {
            return list
        }
        return list.filter { $0.category == category }
    }
    
    func addAccount(title: String, account: String, password: String, note: String, category: AccountCategory) {
        let newAccount = Account(title: title, account: account, password: password, note: note, category: category)
        accounts.append(newAccount)
        saveAccounts()
    }
    
    func updateAccount(_ account: Account) {
        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[index] = account
            saveAccounts()
        }
    }
    
    func deleteAccount(at offsets: IndexSet, in categoryAccounts: [Account]) {
        // We need to find the actual items to delete since we might be viewing a filtered list
        let itemsToDelete = offsets.map { categoryAccounts[$0] }
        itemsToDelete.forEach { item in
            if let index = accounts.firstIndex(where: { $0.id == item.id }) {
                accounts.remove(at: index)
            }
        }
        saveAccounts()
    }
    
    func deleteAccount(_ account: Account) {
        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts.remove(at: index)
            saveAccounts()
        }
    }
    
    private func saveAccounts() {
        if let encoded = try? JSONEncoder().encode(accounts) {
            // Encrypt before saving
            if let encrypted = EncryptionManager.shared.encrypt(encoded) {
                UserDefaults.standard.set(encrypted, forKey: saveKey)
                CloudSyncManager.shared.sync()
            }
        }
    }
    
    private func loadAccounts() {
        if let data = UserDefaults.standard.data(forKey: saveKey) {
            // Try to decrypt first
            if let decrypted = EncryptionManager.shared.decrypt(data),
               let decoded = try? JSONDecoder().decode([Account].self, from: decrypted) {
                accounts = decoded
            } else if let decoded = try? JSONDecoder().decode([Account].self, from: data) {
                // Fallback for legacy unencrypted data
                accounts = decoded
                // Re-save to encrypt it
                saveAccounts()
            }
        }
    }
}
