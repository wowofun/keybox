import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = TokenViewModel()
    @State private var showScanner = false
    @State private var showManualEntry = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Header
                    HStack {
                        Text("Account Box".localized)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        Spacer()
                        
                        Menu {
                            Button {
                                showScanner = true
                            } label: {
                                Label("Scan QR Code".localized, systemImage: "qrcode.viewfinder")
                            }
                            
                            Button {
                                showManualEntry = true
                            } label: {
                                Label("Enter Manually".localized, systemImage: "keyboard")
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(
                                    Theme.primaryGradient
                                )
                                .clipShape(Circle())
                                .shadow(color: Theme.shadowColor, radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search keys...".localized, text: $viewModel.searchText)
                    }
                    .padding(12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                    .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
                    
                    if viewModel.tokens.isEmpty {
                        Spacer()
                        HomeEmptyStateView(showScanner: $showScanner, showManual: $showManualEntry)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.filteredTokens) { token in
                                    NavigationLink(destination: TokenDetailView(viewModel: viewModel, token: token)) {
                                        TokenCard(token: token)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            BiometricManager.shared.authenticateAction(reason: "Authenticate to delete token".localized) { success in
                                                if success {
                                                    viewModel.deleteToken(token)
                                                }
                                            }
                                        } label: {
                                            Label("Delete".localized, systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 10)
                            .padding(.bottom, 100) // Space for floating tab bar
                        }
                    }
                }
            }
            // Hide standard nav bar since we have a custom header
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showScanner) {
                ScannerView { code in
                    handleScannedCode(code)
                }
            }
            .sheet(isPresented: $showManualEntry) {
                ManualEntryView(viewModel: viewModel)
            }
            .alert("Error".localized, isPresented: $showErrorAlert) {
                Button("OK".localized, role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    func handleScannedCode(_ code: String) {
        print("Scanned code: \(code)") // Debugging
        
        guard let url = URL(string: code) else {
            errorMessage = "Invalid QR Code format.".localized
            showErrorAlert = true
            showScanner = false
            return
        }
        
        guard url.scheme == "otpauth" else {
            errorMessage = "Not a valid 2FA QR Code (must start with otpauth://)".localized
            showErrorAlert = true
            showScanner = false
            return
        }
        
        guard url.host == "totp" else {
             errorMessage = "Only TOTP is supported currently.".localized
             showErrorAlert = true
             showScanner = false
             return
        }
        
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems
        
        guard let secret = queryItems?.first(where: { $0.name == "secret" })?.value else {
            errorMessage = "Missing secret in QR Code.".localized
            showErrorAlert = true
            showScanner = false
            return
        }
        
        let issuer = queryItems?.first(where: { $0.name == "issuer" })?.value ?? "Unknown".localized
        let label = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        
        viewModel.addToken(issuer: issuer, accountName: label, secret: secret)
        showScanner = false
    }
}

struct HomeEmptyStateView: View {
    @Binding var showScanner: Bool
    @Binding var showManual: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Theme.subtleGradient)
                    .frame(width: 180, height: 180)
                
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(
                        Theme.primaryGradient
                    )
            }
            
            VStack(spacing: 8) {
                Text("No Keys Yet".localized)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                
                Text("Add your first 2FA account to get started.".localized)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            HStack(spacing: 16) {
                Button {
                    showScanner = true
                } label: {
                    Label("Scan QR".localized, systemImage: "qrcode.viewfinder")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 24)
                        .background(
                            Theme.primaryGradient
                        )
                        .clipShape(Capsule())
                        .shadow(color: Theme.shadowColor, radius: 10, x: 0, y: 5)
                }
                
                Button {
                    showManual = true
                } label: {
                    Label("Manual".localized, systemImage: "keyboard")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 24)
                        .background(
                            Capsule()
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                        )
                }
            }
            .padding(.top, 10)
        }
        .padding()
    }
}
