import Foundation
import SwiftUI
import Combine

class CloudSyncManager: ObservableObject {
    static let shared = CloudSyncManager()
    
    @Published var isCloudSyncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isCloudSyncEnabled, forKey: "isCloudSyncEnabled")
            if isCloudSyncEnabled {
                // Register for notifications immediately when enabled
                setupObserver()
                
                // 1. Trigger sync to ensure we have latest connection
                NSUbiquitousKeyValueStore.default.synchronize()
                
                // 2. Try to load existing data immediately (handles "Restore" case where data is already in KVS)
                loadFromCloud()
                
                // 3. Trigger initial upload immediately.
                // We do NOT use asyncAfter delay anymore, to ensure this runs reliably even if app state changes quickly.
                // Since loadFromCloud() uses smart merge (reading/writing UserDefaults synchronously except for UI),
                // it is safe to sync back immediately to push any offline-created data to Cloud.
                print("☁️ [CloudSync] Sync enabled. Performing initial upload of local data...")
                self.sync()
            } else {
                // Remove observer when disabled
                removeObserver()
            }
        }
    }
    
    @Published var lastSyncDate: Date? {
        didSet {
            if let date = lastSyncDate {
                UserDefaults.standard.set(date, forKey: "lastSyncDate")
            }
        }
    }
    
    private let tokensKey = "saved_tokens_v1"
    private let accountsKey = "saved_accounts_v1"
    
    init() {
        self.isCloudSyncEnabled = UserDefaults.standard.bool(forKey: "isCloudSyncEnabled")
        self.lastSyncDate = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date
        
        if isCloudSyncEnabled {
            setupObserver()
            NSUbiquitousKeyValueStore.default.synchronize()
        }
    }
    
    private func setupObserver() {
        // Remove first to avoid duplicates
        removeObserver()
        NotificationCenter.default.addObserver(self, selector: #selector(ubiquitousKeyValueStoreDidChange), name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: NSUbiquitousKeyValueStore.default)
        print("☁️ [CloudSync] Observer registered")
    }
    
    private func removeObserver() {
        NotificationCenter.default.removeObserver(self, name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: NSUbiquitousKeyValueStore.default)
        print("☁️ [CloudSync] Observer removed")
    }
    
    private func loadFromCloud() {
        print("☁️ [CloudSync] Checking for existing cloud data...")
        var hasUpdates = false
        
        // Merge Tokens
        if let cloudTokens = NSUbiquitousKeyValueStore.default.data(forKey: tokensKey) {
            if mergeAndSave(localKey: tokensKey, cloudData: cloudTokens, type: OTPToken.self) {
                print("☁️ [CloudSync] Merged tokens from cloud")
                hasUpdates = true
            }
        }
        
        // Merge Accounts
        if let cloudAccounts = NSUbiquitousKeyValueStore.default.data(forKey: accountsKey) {
            if mergeAndSave(localKey: accountsKey, cloudData: cloudAccounts, type: Account.self) {
                print("☁️ [CloudSync] Merged accounts from cloud")
                hasUpdates = true
            }
        }
        
        if hasUpdates {
            DispatchQueue.main.async {
                self.lastSyncDate = Date()
                NotificationCenter.default.post(name: Notification.Name("DataDidUpdateFromCloud"), object: nil)
                
                NotificationManager.shared.addNotification(
                    type: .sync,
                    title: "Cloud Sync".localized,
                    message: "Data synchronized from iCloud".localized
                )
                
                // Trigger upload to ensure cloud has the merged result (Local + Cloud)
                print("☁️ [CloudSync] Merged data, syncing back to cloud...")
                self.sync()
            }
        } else {
            print("☁️ [CloudSync] No new data merged from cloud")
        }
    }
    
    /// Merges cloud data with local data.
    /// Strategy: Union by ID. If an item exists in both, the LOCAL version is preserved to prevent overwriting un-synced changes.
    private func mergeAndSave<T: Codable & Identifiable>(localKey: String, cloudData: Data, type: T.Type) -> Bool where T.ID == UUID {
        do {
            // 1. Decode Cloud Data (Try Decrypt first, then Plain)
            var cloudItems: [T] = []
            if let decryptedCloud = EncryptionManager.shared.decrypt(cloudData) {
                cloudItems = (try? JSONDecoder().decode([T].self, from: decryptedCloud)) ?? []
            } else {
                cloudItems = (try? JSONDecoder().decode([T].self, from: cloudData)) ?? []
            }
            
            if cloudItems.isEmpty { return false }
            
            // 2. Decode Local Data (Try Decrypt first, then Plain)
            var localItems: [T] = []
            if let localData = UserDefaults.standard.data(forKey: localKey) {
                if let decryptedLocal = EncryptionManager.shared.decrypt(localData) {
                    localItems = (try? JSONDecoder().decode([T].self, from: decryptedLocal)) ?? []
                } else {
                    localItems = (try? JSONDecoder().decode([T].self, from: localData)) ?? []
                }
            }
            
            // 3. Merge: Create a map of existing items by ID
            // We start with local items map
            var itemMap = Dictionary(uniqueKeysWithValues: localItems.map { ($0.id, $0) })
            var didChange = false
            
            for item in cloudItems {
                if itemMap[item.id] == nil {
                    // Item exists in Cloud but not locally: ADD IT
                    itemMap[item.id] = item
                    didChange = true
                }
                // If it exists locally, we SKIP the cloud version, preserving local edits.
            }
            
            // 4. Save back if we added anything
            if didChange {
                let finalItems = Array(itemMap.values)
                let newData = try JSONEncoder().encode(finalItems)
                // Encrypt before saving
                if let encryptedData = EncryptionManager.shared.encrypt(newData) {
                    UserDefaults.standard.set(encryptedData, forKey: localKey)
                    return true
                }
            }
            
            return false
            
        } catch {
            print("☁️ [CloudSync] Merge error for \(type): \(error)")
            return false
        }
    }
    
    func sync(force: Bool = false) {
        if !force {
            guard isCloudSyncEnabled else {
                print("☁️ [CloudSync] Sync skipped: Cloud Sync is disabled in settings. (Enabled state: \(isCloudSyncEnabled))")
                return
            }
        }
        
        print("☁️ [CloudSync] Starting upload (Force: \(force))...")
        
        // Upload local data to Cloud
        if let tokensData = UserDefaults.standard.data(forKey: tokensKey) {
            NSUbiquitousKeyValueStore.default.set(tokensData, forKey: tokensKey)
            print("☁️ [CloudSync] Uploaded tokens: \(tokensData.count) bytes")
        }
        
        if let accountsData = UserDefaults.standard.data(forKey: accountsKey) {
            NSUbiquitousKeyValueStore.default.set(accountsData, forKey: accountsKey)
            print("☁️ [CloudSync] Uploaded accounts: \(accountsData.count) bytes")
        }
        
        let success = NSUbiquitousKeyValueStore.default.synchronize()
        if success {
            print("☁️ [CloudSync] Upload triggered successfully. Waiting for system...")
        } else {
            print("⚠️ [CloudSync] Upload trigger FAILED. Check iCloud settings/network.")
        }
        
        DispatchQueue.main.async {
            self.lastSyncDate = Date()
        }
    }
    
    // Manual trigger for debugging/testing
    func forceRestoreFromCloud() {
        print("☁️ [CloudSync] Force restoring from cloud...")
        loadFromCloud() // Use the merge logic instead of blind restore
    }
    
    @objc private func ubiquitousKeyValueStoreDidChange(notification: NSNotification) {
        guard isCloudSyncEnabled else { return }
        print("☁️ [CloudSync] Cloud data changed notification received.")
        
        // Use the smart merge logic instead of overwriting
        loadFromCloud()
    }
}
