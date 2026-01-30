import Foundation

struct OTPToken: Identifiable, Codable {
    var id: UUID = UUID()
    var issuer: String
    var accountName: String
    var secret: String
    var period: TimeInterval = 30
    var digits: Int = 6
    var colorHex: String? // Store a color for UI
    
    // Computed property to get current code
    var currentCode: String {
        return OTPGenerator.generateTOTP(secret: secret, timeInterval: period, digits: digits) ?? "000000"
    }
    
    // Progress of the current period (0.0 to 1.0)
    var progress: Double {
        let timeIntervalSince1970 = Date().timeIntervalSince1970
        let remaining = period - (timeIntervalSince1970.truncatingRemainder(dividingBy: period))
        return remaining / period
    }
}
