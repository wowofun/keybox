import SwiftUI

struct AddAccountView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: AccountViewModel
    
    @State private var title: String = ""
    @State private var account: String = ""
    @State private var password: String = ""
    @State private var note: String = ""
    @State private var selectedCategory: AccountCategory = .game
    @State private var isPasswordVisible: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Please enter title".localized, text: $title)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Please enter account".localized, text: $account)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                } header: {
                    Text("Title".localized)
                }
                
                Section {
                    HStack {
                        if isPasswordVisible {
                            TextField("Please enter password".localized, text: $password)
                        } else {
                            SecureField("Please enter password".localized, text: $password)
                        }
                        
                        Button(action: {
                            isPasswordVisible.toggle()
                        }) {
                            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Quick Generate Button
                    Button(action: {
                        password = generateStrongPassword()
                        isPasswordVisible = true
                    }) {
                        Label("Generate New".localized, systemImage: "key.fill")
                            .font(.caption)
                            .foregroundColor(Theme.primary)
                    }
                } header: {
                    Text("Password".localized)
                }
                
                Section {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 12) {
                        ForEach(AccountCategory.allCases) { category in
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(selectedCategory == category ? colorForCategory(category) : Color.gray.opacity(0.1))
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: category.icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(selectedCategory == category ? .white : .gray)
                                }
                                
                                Text(category.localizedName)
                                    .font(.caption)
                                    .foregroundColor(selectedCategory == category ? .primary : .secondary)
                            }
                            .onTapGesture {
                                withAnimation {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Category".localized) // We might need to add this key if not present, but usually "Category" is implied or we can add "Select Category"
                }
                
                Section {
                    TextField("Please enter note".localized, text: $note, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Note".localized)
                }
            }
            .navigationTitle("Add Account".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add Now".localized) {
                        addAccount()
                    }
                    .disabled(!isValid)
                    .fontWeight(.bold)
                    .tint(Theme.primary)
                }
            }
            .tint(Theme.primary)
        }
    }
    
    private var isValid: Bool {
        !title.isEmpty && !account.isEmpty && !password.isEmpty
    }
    
    private func addAccount() {
        viewModel.addAccount(title: title, account: account, password: password, note: note, category: selectedCategory)
        presentationMode.wrappedValue.dismiss()
    }
    
    private func generateStrongPassword() -> String {
        let length = 16
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
}
