import SwiftUI

struct AccountDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: AccountViewModel
    @State var account: Account
    
    // View Mode State
    @State private var isEditing = false
    @State private var isPasswordVisibleInViewMode = false
    
    // Edit Mode State (Temporary changes)
    @State private var title: String = ""
    @State private var accountName: String = ""
    @State private var password: String = ""
    @State private var note: String = ""
    @State private var selectedCategory: AccountCategory = .other
    @State private var isPasswordVisibleInEditMode = false
    
    @State private var showDeleteAlert = false
    
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
                            Text(isEditing ? "Cancel".localized : "Back".localized) // "Back" usually automatic, but we custom
                        }
                        .foregroundColor(Theme.primary)
                        .font(.system(size: 17))
                    }
                    
                    Spacer()
                    
                    Text(isEditing ? "Edit".localized : "Account Details".localized)
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
                                Text("Delete Account".localized)
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
        .navigationBarHidden(true) // Use custom nav bar
        .onAppear {
            loadData()
        }
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("Delete Account".localized),
                message: Text("Are you sure you want to delete this account?".localized),
                primaryButton: .destructive(Text("Delete".localized)) {
                    deleteAccount()
                },
                secondaryButton: .cancel(Text("Cancel".localized))
            )
        }
    }
    
    // MARK: - Views
    
    var readOnlyView: some View {
        VStack(spacing: 0) {
            // Header with Icon
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(colorForCategory(account.category).opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: account.category.icon)
                        .font(.system(size: 40))
                        .foregroundColor(colorForCategory(account.category))
                }
                .padding(.top, 20)
                
                Text(account.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(account.category.localizedName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 30)
            
            // Details List
            VStack(spacing: 0) {
                DetailRow(label: "Account".localized, value: account.account)
                Divider().padding(.leading, 16)
                
                // Password Row
                HStack {
                    Text("Password".localized)
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .leading)
                    
                    Spacer()
                    
                    if isPasswordVisibleInViewMode {
                        Text(account.password)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.primary)
                    } else {
                        Text("••••••••")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: {
                        if isPasswordVisibleInViewMode {
                            isPasswordVisibleInViewMode = false
                        } else {
                            BiometricManager.shared.authenticateAction(reason: "Authenticate to view password".localized) { success in
                                if success {
                                    isPasswordVisibleInViewMode = true
                                }
                            }
                        }
                    }) {
                        Image(systemName: isPasswordVisibleInViewMode ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(Theme.primary)
                            .padding(8)
                            .background(Theme.primary.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 8)
                    
                    Button(action: {
                        BiometricManager.shared.authenticateAction(reason: "Authenticate to copy password".localized) { success in
                            if success {
                                UIPasteboard.general.string = account.password
                            }
                        }
                    }) {
                        Image(systemName: "doc.on.doc.fill")
                            .foregroundColor(Theme.primary)
                            .padding(8)
                            .background(Theme.primary.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                Divider().padding(.leading, 16)
                
                // Note Row
                VStack(alignment: .leading, spacing: 8) {
                    Text("Note".localized)
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                    
                    Text(account.note.isEmpty ? "None".localized : account.note)
                        .font(.body)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal, 16)
        }
    }
    
    var editView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 0) {
                InputRow(label: "Title".localized, text: $title, placeholder: "Enter title".localized)
                Divider().padding(.leading, 16)
                
                InputRow(label: "Account".localized, text: $accountName, placeholder: "Enter account".localized)
                Divider().padding(.leading, 16)
                
                // Password Edit
                HStack {
                    Text("Password".localized)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                        .frame(width: 80, alignment: .leading)
                    
                    Spacer()
                    
                    if isPasswordVisibleInEditMode {
                        TextField("Enter password".localized, text: $password)
                            .font(.system(size: 16))
                            .multilineTextAlignment(.trailing)
                    } else {
                        SecureField("Enter password".localized, text: $password)
                            .font(.system(size: 16))
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Button(action: {
                        isPasswordVisibleInEditMode.toggle()
                    }) {
                        Image(systemName: isPasswordVisibleInEditMode ? "eye.slash" : "eye")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                
                Divider().padding(.leading, 16)
                
                // Note Edit
                HStack(alignment: .top) {
                    Text("Note".localized)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                        .frame(width: 80, alignment: .leading)
                        .padding(.top, 8)
                    
                    Spacer()
                    
                    TextField("Optional notes".localized, text: $note, axis: .vertical)
                        .font(.system(size: 16))
                        .multilineTextAlignment(.trailing)
                        .padding(.vertical, 8)
                }
                .padding(.horizontal)
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal, 16)
            
            // Category Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Category".localized)
                    .font(.headline)
                    .padding(.horizontal, 20)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(AccountCategory.allCases) { category in
                            CategoryPill(category: category, isSelected: selectedCategory == category) {
                                withAnimation {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func loadData() {
        title = account.title
        accountName = account.account
        password = account.password
        note = account.note
        selectedCategory = account.category
        isPasswordVisibleInViewMode = false
    }
    
    private func saveChanges() {
        BiometricManager.shared.authenticateAction(reason: "Authenticate to save changes".localized) { success in
            if success {
                var updatedAccount = account
                updatedAccount.title = title
                updatedAccount.account = accountName
                updatedAccount.password = password
                updatedAccount.note = note
                updatedAccount.category = selectedCategory
                
                viewModel.updateAccount(updatedAccount)
                
                // Update local state to reflect changes immediately in View Mode
                self.account = updatedAccount
                
                withAnimation {
                    isEditing = false
                }
            }
        }
    }
    
    private func deleteAccount() {
        BiometricManager.shared.authenticateAction(reason: "Authenticate to delete account".localized) { success in
            if success {
                viewModel.deleteAccount(account)
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding()
    }
}

// Reuse InputRow from previous implementation, but slightly adjusted width
struct InputRow: View {
    let label: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .frame(width: 80, alignment: .leading)
            
            Spacer()
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .multilineTextAlignment(.trailing)
        }
        .padding()
    }
}
