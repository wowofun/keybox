import Foundation

enum AccountCategory: String, Codable, CaseIterable, Identifiable {
    case game = "Game"
    case app = "APP"
    case email = "Email"
    case website = "Website"
    case other = "Other"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .game: return "gamecontroller.fill"
        case .app: return "apps.iphone"
        case .email: return "envelope.fill"
        case .website: return "desktopcomputer"
        case .other: return "square.grid.2x2.fill"
        }
    }
    
    var color: String {
        switch self {
        case .game: return "Red"
        case .app: return "Blue"
        case .email: return "Green"
        case .website: return "Purple"
        case .other: return "Orange"
        }
    }
    
    var localizedName: String {
        return rawValue.localized
    }
}

struct Account: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var account: String
    var password: String
    var note: String
    var category: AccountCategory
    var createDate: Date = Date()
    
    // Implement Hashable and Equatable manually to avoid navigation issues when properties change
    static func == (lhs: Account, rhs: Account) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
