import SwiftUI

struct AccountBoxView: View {
    @ObservedObject private var viewModel = AccountViewModel.shared
    @State private var selectedCategoryFilter: AccountCategory? = nil // nil means "All"
    @State private var showAddSheet = false
    @State private var navPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navPath) {
            ZStack {
                Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Custom Header
                    HStack {
                        Text("Account Box".localized) // Localized to "Vault" / "密码本"
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: {
                            showAddSheet = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Theme.primary)
                                .clipShape(Circle())
                                .shadow(color: Theme.shadowColor, radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 16)
                    .background(Color(UIColor.systemGroupedBackground)) // Blend with bg
                    
                    // Filter Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            FilterPill(title: "All".localized, isSelected: selectedCategoryFilter == nil) {
                                withAnimation {
                                    selectedCategoryFilter = nil
                                }
                            }
                            
                            ForEach(AccountCategory.allCases) { category in
                                FilterPill(title: category.localizedName, isSelected: selectedCategoryFilter == category) {
                                    withAnimation {
                                        selectedCategoryFilter = category
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    .padding(.bottom, 8)
                    
                    // List
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            let accounts = viewModel.accounts(for: selectedCategoryFilter)
                            if accounts.isEmpty {
                                AccountBoxEmptyView(message: "No Accounts Yet".localized)
                                    .padding(.top, 60)
                            } else {
                                ForEach(accounts) { account in
                                    AccountCard(account: account, viewModel: viewModel)
                                        .onTapGesture {
                                            navPath.append(account)
                                        }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 100) // Space for TabBar
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: Account.self) { account in
                AccountDetailView(viewModel: viewModel, account: account)
            }
            .sheet(isPresented: $showAddSheet) {
                AddAccountView(viewModel: viewModel)
            }
        }
    }
}

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(isSelected ? Theme.primary : Color(UIColor.systemBackground))
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
}

struct AccountCard: View {
    let account: Account
    @ObservedObject var viewModel: AccountViewModel
    @State private var showPassword = false
    @State private var copied = false
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorForCategory(account.category).opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: account.category.icon)
                        .font(.system(size: 20))
                        .foregroundColor(colorForCategory(account.category))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(account.account)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: 8) {
                    Button(action: {
                        BiometricManager.shared.authenticateAction(reason: "Authenticate to copy password".localized) { success in
                            if success {
                                UIPasteboard.general.string = account.password
                                withAnimation {
                                    copied = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        copied = false
                                    }
                                }
                            }
                        }
                    }) {
                        Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
                            .font(.system(size: 16))
                            .foregroundColor(copied ? Theme.primary : .gray)
                            .frame(width: 32, height: 32)
                            .background(Color(UIColor.systemGray6))
                            .clipShape(Circle())
                    }
                    
                    Button(action: {
                        if showPassword {
                            showPassword = false
                        } else {
                            BiometricManager.shared.authenticateAction(reason: "Authenticate to view password".localized) { success in
                                if success {
                                    showPassword = true
                                }
                            }
                        }
                    }) {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .frame(width: 32, height: 32)
                            .background(Color(UIColor.systemGray6))
                            .clipShape(Circle())
                    }
                }
            }
            
            if showPassword {
                HStack {
                    Text(account.password)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(10)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
                .transition(.opacity)
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
        .contextMenu {
            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                Label("Delete".localized, systemImage: "trash")
            }
        }
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                    title: Text("Delete".localized),
                    message: Text("Are you sure you want to delete this account?".localized),
                    primaryButton: .destructive(Text("Delete".localized)) {
                    BiometricManager.shared.authenticateAction(reason: "Authenticate to delete account".localized) { success in
                        if success {
                            viewModel.deleteAccount(account)
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
}

struct AccountBoxEmptyView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.square.stack")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.5))
            Text(message)
                .font(.headline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .listRowSeparator(.hidden)
    }
}
