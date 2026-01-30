import SwiftUI

struct ManualEntryView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: TokenViewModel
    
    @State private var issuer = ""
    @State private var accountName = ""
    @State private var secret = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Account Details".localized)) {
                    TextField("Issuer (e.g. Google)".localized, text: $issuer)
                    TextField("Account Name (e.g. user@email.com)".localized, text: $accountName)
                }
                
                Section(header: Text("Secret Key".localized), footer: Text("Enter the key provided by the service.".localized)) {
                    TextField("Secret Key".localized, text: $secret)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
            }
            .hideKeyboardWhenTappedAround()
            .navigationTitle("Add Account".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add".localized) {
                        viewModel.addToken(issuer: issuer, accountName: accountName, secret: secret)
                        dismiss()
                    }
                    .disabled(secret.isEmpty || accountName.isEmpty)
                    .tint(Theme.primary)
                }
            }
            .tint(Theme.primary)
        }
    }
}
