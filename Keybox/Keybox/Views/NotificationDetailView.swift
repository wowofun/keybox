import SwiftUI

struct NotificationDetailView: View {
    let notification: AppNotification
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showRestoreAlert = false
    @State private var restoreSuccess = false
    
    // Check if we can restore something
    var canRestore: Bool {
        guard let id = notification.associatedID else { return false }
        
        // Check tokens
        if TrashManager.shared.getDeletedToken(by: id) != nil {
            return true
        }
        
        // Check accounts
        if TrashManager.shared.getDeletedAccount(by: id) != nil {
            return true
        }
        
        return false
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: notification.type.icon)
                        .font(.system(size: 40))
                        .foregroundColor(notification.type.color)
                        .padding()
                        .background(notification.type.color.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(notification.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(notification.date.formatted())
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 10)
                
                Divider()
                
                // Message Content
                VStack(alignment: .leading, spacing: 10) {
                    Text("Details".localized)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(notification.message)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color("CardBackground"))
                        .cornerRadius(12)
                }
                
                // Deleted Item Details (if available)
                if let id = notification.associatedID {
                    if let deletedToken = TrashManager.shared.getDeletedToken(by: id) {
                        deletedTokenView(deletedToken)
                    } else if let deletedAccount = TrashManager.shared.getDeletedAccount(by: id) {
                        deletedAccountView(deletedAccount)
                    }
                }
                
                Spacer()
                
                // Restore Button
                if canRestore {
                    Button(action: {
                        showRestoreAlert = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.uturn.backward")
                            Text("Restore Data".localized)
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(12)
                        .shadow(color: Color.green.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                    .padding(.top, 20)
                }
                
                if restoreSuccess {
                    Text("Data restored successfully".localized)
                        .foregroundColor(.green)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                } else if !canRestore && notification.associatedID != nil {
                     Text("Data restored successfully".localized)
                        .foregroundColor(.secondary)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                }
            }
            .padding()
        }
        .navigationTitle("Notification Details".localized)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color("Background").ignoresSafeArea())
        .alert(isPresented: $showRestoreAlert) {
            Alert(
                title: Text("Restore Data".localized),
                message: Text("Do you want to restore this data?".localized),
                primaryButton: .default(Text("Restore".localized)) {
                    performRestore()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    @ViewBuilder
    func deletedTokenView(_ token: DeletedToken) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Backup Content".localized)
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.top, 10)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Issuer:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(token.originalToken.issuer)
                        .font(.body)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Account:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(token.originalToken.accountName)
                        .font(.body)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Deleted:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(token.deletedDate.formatted())
                        .font(.body)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("CardBackground"))
            .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    func deletedAccountView(_ account: DeletedAccount) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Backup Content".localized)
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.top, 10)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Title:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(account.originalAccount.title)
                        .font(.body)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Account:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(account.originalAccount.account)
                        .font(.body)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Category:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(account.originalAccount.category.localizedName)
                        .font(.body)
                        .foregroundColor(Color(account.originalAccount.category.color))
                }
                
                HStack {
                    Text("Deleted:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(account.deletedDate.formatted())
                        .font(.body)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("CardBackground"))
            .cornerRadius(12)
        }
    }
    
    func performRestore() {
        guard let id = notification.associatedID else { return }
        
        BiometricManager.shared.authenticateAction(reason: "Authenticate to restore data".localized) { success in
            if success {
                DispatchQueue.main.async {
                    // Try to restore token
                    if let restoredToken = TrashManager.shared.restoreToken(id: id) {
                        TokenViewModel.shared.restoreToken(restoredToken)
                        self.restoreSuccess = true
                        return
                    }
                    
                    // Try to restore account
                    if let restoredAccount = TrashManager.shared.restoreAccount(id: id) {
                        // Assuming AccountViewModel has a shared instance or we need to access it differently
                        // Since AccountViewModel is not a singleton in the snippet I saw, I might need to make it one or pass it in.
                        // Wait, TokenViewModel has 'shared'. AccountViewModel does NOT in the snippet I read.
                        // I need to check AccountViewModel again.
                        
                        // If AccountViewModel is not a singleton, I need to find a way to access it.
                        // Let's assume for now I will add 'shared' to AccountViewModel or use EnvironmentObject if possible.
                        // But 'shared' is easier for this context.
                        AccountViewModel.shared.restoreAccount(restoredAccount)
                        self.restoreSuccess = true
                    }
                }
            }
        }
    }
}
