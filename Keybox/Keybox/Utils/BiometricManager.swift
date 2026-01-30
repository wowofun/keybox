import Foundation
import LocalAuthentication
import Combine

class BiometricManager: ObservableObject {
    static let shared = BiometricManager()
    
    @Published var isFaceIDEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isFaceIDEnabled, forKey: "isFaceIDEnabled")
        }
    }
    
    // Authenticate with a completion handler for specific actions (e.g., reveal password)
    func authenticateAction(reason: String, completion: @escaping (Bool) -> Void) {
        print("🔍 [BiometricManager] authenticateAction called. Reason: \(reason)")
        print("🔍 [BiometricManager] isFaceIDEnabled: \(isFaceIDEnabled)")
        
        if !isFaceIDEnabled {
            // If FaceID is disabled in settings, allow action immediately
            print("🔍 [BiometricManager] FaceID is disabled in settings. Skipping auth.")
            completion(true)
            return
        }
        
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            print("🔍 [BiometricManager] Starting FaceID evaluation...")
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    print("🔍 [BiometricManager] FaceID result: success=\(success), error=\(String(describing: authenticationError))")
                    completion(success)
                }
            }
        } else {
            // Biometrics unavailable but enabled in settings? 
            // Fallback to true or handle error. For now, allow if system fails.
            print("🔍 [BiometricManager] canEvaluatePolicy failed: \(String(describing: error))")
            DispatchQueue.main.async {
                completion(true)
            }
        }
    }
    
    @Published var isUnlocked = false
    @Published var biometricType: LABiometryType = .none
    
    init() {
        self.isFaceIDEnabled = UserDefaults.standard.bool(forKey: "isFaceIDEnabled")
        checkBiometricType()
    }
    
    func checkBiometricType() {
        // Safety check: Ensure Info.plist has the required key
        guard Bundle.main.object(forInfoDictionaryKey: "NSFaceIDUsageDescription") != nil else {
            print("⚠️ WARNING: NSFaceIDUsageDescription is missing from Info.plist. Face ID will be disabled to prevent crashes.")
            biometricType = .none
            return
        }
        
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricType = context.biometryType
        } else {
            biometricType = .none
        }
    }
    
    func authenticate() {
        if !isFaceIDEnabled {
            isUnlocked = true
            return
        }
        
        // Safety check: Ensure Info.plist has the required key
        guard Bundle.main.object(forInfoDictionaryKey: "NSFaceIDUsageDescription") != nil else {
            print("⚠️ CRITICAL: NSFaceIDUsageDescription is missing. Skipping authentication to prevent crash.")
            // Fallback: Unlock automatically or require password (here we unlock to avoid lockout during dev)
            DispatchQueue.main.async {
                self.isUnlocked = true
            }
            return
        }
        
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Unlock with Face ID".localized
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self.isUnlocked = true
                        
                        // Log unlock event
                        NotificationManager.shared.addNotification(
                            type: .security,
                            title: "App Unlocked".localized,
                            message: "Unlocked via FaceID".localized
                        )
                    } else {
                        self.isUnlocked = false
                    }
                }
            }
        } else {
            // No biometrics available
            DispatchQueue.main.async {
                self.isUnlocked = true
            }
        }
    }
}
