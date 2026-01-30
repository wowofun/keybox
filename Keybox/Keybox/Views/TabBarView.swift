import SwiftUI

struct TabBarView: View {
    @State private var selectedTab: Tab = .home
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    enum Tab {
        case home
        case accountBox
        case generator
        case settings
    }
    
    init() {
        UITabBar.appearance().isHidden = true
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Content
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .accountBox:
                    AccountBoxView()
                case .generator:
                    PasswordGeneratorView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 110) // Increased to ensure no occlusion
            }
            
            // Floating Tab Bar
            HStack(spacing: 0) {
                TabBarItem(icon: "key.fill", title: "Keys".localized, isSelected: selectedTab == .home) {
                    selectedTab = .home
                }
                
                TabBarItem(icon: "archivebox.fill", title: "Tab_PasswordBox".localized, isSelected: selectedTab == .accountBox) {
                    selectedTab = .accountBox
                }
                
                TabBarItem(icon: "lock.shield.fill", title: "Gen".localized, isSelected: selectedTab == .generator) {
                    selectedTab = .generator
                }
                
                TabBarItem(icon: "gearshape.fill", title: "Settings".localized, isSelected: selectedTab == .settings) {
                    selectedTab = .settings
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 10)
            .background(.ultraThinMaterial)
            .background(Color.white.opacity(0.6)) // Fallback/Tint
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 8)
            .padding(.horizontal, 24)
            .padding(.bottom, 10) // Float slightly above the safe area
        }
        .ignoresSafeArea(.keyboard)
        // Force redraw when language changes
        .id(localizationManager.language)
    }
}

struct TabBarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .frame(height: 24)
                    .foregroundColor(isSelected ? Theme.primary : .gray.opacity(0.8))
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? Theme.primary : .gray.opacity(0.8))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false) // Prevent truncation/wrapping issues
            }
            .frame(maxWidth: .infinity) // Take up available space evenly
            .contentShape(Rectangle()) // Make entire area tappable
        }
    }
}
