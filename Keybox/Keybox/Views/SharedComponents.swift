import SwiftUI

// MARK: - Global Helpers

func colorForCategory(_ category: AccountCategory) -> Color {
    switch category {
    case .game: return .red
    case .app: return .blue
    case .email: return .green
    case .website: return .purple
    case .other: return .orange
    }
}

// MARK: - Reusable Components

struct CategoryPill: View {
    let category: AccountCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                Text(category.localizedName)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(isSelected ? colorForCategory(category) : Color(UIColor.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
            // Optional: Add a subtle border or shadow if needed
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
}
