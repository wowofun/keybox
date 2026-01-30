import SwiftUI

struct TokenDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: TokenViewModel
    @State var token: OTPToken
    
    // View Mode State
    @State private var isEditing = false
    @State private var isSecretVisible = false
    
    // Edit Mode State
    @State private var issuer: String = ""
    @State private var accountName: String = ""
    @State private var secret: String = ""
    
    @State private var showDeleteAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Custom Navigation Bar
                HStack {
                    Button(action: {
                        if isEditing {
                            // Cancel editing
                            withAnimation {
                                isEditing = false
                                loadData() // Reset fields
                            }
                        } else {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text(isEditing ? "Cancel".localized : "Back".localized)
                        }
                        .foregroundColor(Theme.primary)
                        .font(.system(size: 17))
                    }
                    
                    Spacer()
                    
                    Text(isEditing ? "Edit".localized : "Token Details".localized)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if !isEditing {
                        Button(action: {
                            withAnimation {
                                loadData() // Ensure data is loaded
                                isEditing = true
                            }
                        }) {
                            Text("Edit".localized)
                                .font(.system(size: 17))
                                .foregroundColor(Theme.primary)
                        }
                    } else {
                        // Placeholder to balance layout
                        Text("Edit".localized)
                            .font(.system(size: 17))
                            .foregroundColor(.clear)
                    }
                }
                .padding()
                .background(Color(UIColor.systemGroupedBackground))
                
                ScrollView {
                    VStack(spacing: 24) {
                        if isEditing {
                            editView
                        } else {
                            readOnlyView
                        }
                        
                        if isEditing {
                            // Save Button
                            Button(action: saveChanges) {
                                Text("Confirm".localized)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Theme.primaryGradient)
                                    .cornerRadius(25)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 20)
                        } else {
                            // Delete Button in View Mode
                            Button(action: {
                                showDeleteAlert = true
                            }) {
                                Text("Delete".localized)
                                    .font(.headline)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color(UIColor.systemBackground))
                                    .cornerRadius(25)
                                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 20)
                        }
                    }
                    .padding(.bottom, 40)
                    .padding(.top, 10)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadData()
        }
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("Delete".localized),
                message: Text("Are you sure you want to delete this account?".localized),
                primaryButton: .destructive(Text("Delete".localized)) {
                    deleteToken()
                },
                secondaryButton: .cancel(Text("Cancel".localized))
            )
        }
        .alert("Error".localized, isPresented: $showErrorAlert) {
            Button("OK".localized, role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Views
    
    var readOnlyView: some View {
        VStack(spacing: 0) {
            // Header with Icon
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Theme.primaryGradient)
                        .frame(width: 80, height: 80)
                    
                    Text(String(token.issuer.prefix(1)).uppercased())
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.top, 20)
                .shadow(color: Theme.shadowColor, radius: 10, x: 0, y: 5)
                
                Text(token.issuer)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(token.accountName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 30)
            
            // Details List
            VStack(spacing: 0) {
                TokenDetailRow(label: "Issuer".localized, value: token.issuer)
                Divider().padding(.leading, 16)
                
                TokenDetailRow(label: "Account Name".localized, value: token.accountName)
                Divider().padding(.leading, 16)
                
                // Secret Key Row
                HStack {
                    Text("Secret Key".localized)
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .frame(width: 100, alignment: .leading)
                    
                    Spacer()
                    
                    if isSecretVisible {
                        Text(token.secret)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.trailing)
                    } else {
                        Text("••••••••")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: {
                        if isSecretVisible {
                            isSecretVisible = false
                        } else {
                            BiometricManager.shared.authenticateAction(reason: "Authenticate to view password".localized) { success in
                                if success {
                                    isSecretVisible = true
                                    
                                    // Log View Secret Action
                                    NotificationManager.shared.addNotification(
                                        type: .view,
                                        title: "Viewed Secret".localized,
                                        message: String(format: "Viewed secret for account".localized, "\(token.issuer) (\(token.accountName))")
                                    )
                                }
                            }
                        }
                    }) {
                        Image(systemName: isSecretVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(Theme.primary)
                            .padding(8)
                    }
                }
                .padding()
                .background(Color(UIColor.systemBackground))
            }
            .cornerRadius(12)
            .padding(.horizontal)
            .shadow(color: .black.opacity(0.02), radius: 5, x: 0, y: 2)
        }
    }
    
    var editView: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Issuer".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
                
                TextField("Issuer (e.g. Google)".localized, text: $issuer)
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Account Name".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
                
                TextField("Account Name (e.g. user@email.com)".localized, text: $accountName)
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Secret Key".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
                
                TextField("Secret Key".localized, text: $secret)
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                    .textInputAutocapitalization(.characters)
                    .disableAutocorrection(true)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Actions
    
    private func loadData() {
        issuer = token.issuer
        accountName = token.accountName
        secret = token.secret
    }
    
    private func saveChanges() {
        // Validation
        guard !issuer.isEmpty, !accountName.isEmpty, !secret.isEmpty else {
            errorMessage = "Please fill in all fields".localized
            showErrorAlert = true
            return
        }
        
        // FaceID Verification
        BiometricManager.shared.authenticateAction(reason: "Authenticate to save changes".localized) { success in
            if success {
                // Update token
                var updatedToken = token
                updatedToken.issuer = issuer
                updatedToken.accountName = accountName
                updatedToken.secret = secret.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                
                viewModel.updateToken(updatedToken)
                
                // Update local state
                self.token = updatedToken
                
                withAnimation {
                    isEditing = false
                }
            }
        }
    }
    
    private func deleteToken() {
        BiometricManager.shared.authenticateAction(reason: "Authenticate to delete account".localized) { success in
            if success {
                viewModel.deleteToken(token)
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

// Helper View for Read-Only Rows
struct TokenDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
            
            // Placeholder for alignment with eye icon in secret row
            Color.clear
                .frame(width: 40, height: 20)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
}
