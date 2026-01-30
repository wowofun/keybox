import SwiftUI
import CoreImage.CIFilterBuiltins

struct PasswordGeneratorView: View {
    @State private var selectedTab: GeneratorTab = .password
    
    enum GeneratorTab: String, CaseIterable {
        case password = "Password"
        case totp = "2FA TOTP"
        
        var localized: String {
            switch self {
            case .password: return "Password".localized
            case .totp: return "2FA / TOTP".localized
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Custom Segmented Control
                    HStack(spacing: 0) {
                        ForEach(GeneratorTab.allCases, id: \.self) { tab in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedTab = tab
                                }
                            } label: {
                                Text(tab.localized)
                                    .font(.headline)
                                    .foregroundColor(selectedTab == tab ? .white : .primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        ZStack {
                                            if selectedTab == tab {
                                                Capsule()
                                                    .fill(Theme.primaryGradient)
                                                    .matchedGeometryEffect(id: "TabBackground", in: namespace)
                                            }
                                        }
                                    )
                                    .contentShape(Capsule())
                            }
                        }
                    }
                    .padding(4)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    // Content
                    ScrollView {
                        if selectedTab == .password {
                            PasswordGeneratorSubView()
                        } else {
                            TOTPGeneratorSubView()
                        }
                    }
                }
                .padding(.top, 20)
            }
            .navigationTitle("Generator".localized)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    @Namespace private var namespace
}

struct PasswordGeneratorSubView: View {
    @State private var passwordLength: Double = 12
    @State private var useUppercase = true
    @State private var useNumbers = true
    @State private var useSymbols = true
    @State private var generatedPassword = ""
    @State private var showCopiedAlert = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Password Display
            VStack(spacing: 16) {
                Text(generatedPassword)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                    .onTapGesture {
                        copyToClipboard()
                    }
                
                Button {
                    copyToClipboard()
                } label: {
                    Label("Copy Password".localized, systemImage: "doc.on.doc")
                        .font(.headline)
                        .foregroundColor(Theme.primary)
                }
            }
            .padding(.horizontal)
            
            // Controls
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Length".localized)
                        Spacer()
                        Text("\(Int(passwordLength))")
                            .fontWeight(.bold)
                            .foregroundColor(Theme.primary)
                    }
                    Slider(value: $passwordLength, in: 6...32, step: 1)
                        .tint(Theme.primary)
                }
                .padding()
                
                Divider()
                
                Toggle("Uppercase (A-Z)".localized, isOn: $useUppercase)
                    .tint(Theme.primary)
                    .padding()
                
                Divider()
                
                Toggle("Numbers (0-9)".localized, isOn: $useNumbers)
                    .tint(Theme.primary)
                    .padding()
                
                Divider()
                
                Toggle("Symbols (!@#)".localized, isOn: $useSymbols)
                    .tint(Theme.primary)
                    .padding()
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
            .padding(.horizontal)
            
            // Generate Button
            Button {
                generateNewPassword()
            } label: {
                Text("Generate New".localized)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        Theme.primaryGradient
                    )
                    .clipShape(Capsule())
                    .shadow(color: Theme.shadowColor, radius: 10, x: 0, y: 5)
            }
            .padding(.horizontal)
            
            Spacer()
                .frame(height: 120) // Increased to avoid blocking by TabBar
        }
        .onAppear {
            if generatedPassword.isEmpty {
                generateNewPassword()
            }
        }
        .overlay(
            // Toast for copied
            Group {
                if showCopiedAlert {
                    VStack {
                        Spacer()
                        Text("Copied!".localized)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(Color.black.opacity(0.7))
                            .clipShape(Capsule())
                            .padding(.bottom, 0)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(100)
                }
            }
        )
    }
    
    func generateNewPassword() {
        generatedPassword = Self.generatePassword(
            length: Int(passwordLength),
            useUppercase: useUppercase,
            useNumbers: useNumbers,
            useSymbols: useSymbols
        )
    }
    
    func copyToClipboard() {
        UIPasteboard.general.string = generatedPassword
        withAnimation {
            showCopiedAlert = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopiedAlert = false
            }
        }
    }
    
    static func generatePassword(length: Int, useUppercase: Bool, useNumbers: Bool, useSymbols: Bool) -> String {
        let lowercase = "abcdefghijklmnopqrstuvwxyz"
        let uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let numbers = "0123456789"
        let symbols = "!@#$%^&*()_+-=[]{}|;:,.<>?"
        
        var charset = lowercase
        if useUppercase { charset += uppercase }
        if useNumbers { charset += numbers }
        if useSymbols { charset += symbols }
        
        if charset.isEmpty { charset = lowercase }
        
        return String((0..<length).map { _ in
            charset.randomElement()!
        })
    }
}

struct TOTPGeneratorSubView: View {
    @State private var secretKey: String = ""
    @State private var issuer: String = "KeyBox"
    @State private var accountName: String = UserProfileManager.shared.nickname
    @State private var qrCodeImage: UIImage?
    @State private var showSavedAlert = false
    // @StateObject private var tokenViewModel = TokenViewModel() // Removed local instance
    
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    
    var body: some View {
        VStack(spacing: 24) {
            // QR Code Display
            VStack(spacing: 16) {
                if let qrCodeImage = qrCodeImage {
                    Image(uiImage: qrCodeImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 200, height: 200)
                        .cornerRadius(16)
                        .overlay(Text("Generating...".localized).foregroundColor(.gray))
                }
                
                // Secret Key Display
                VStack(spacing: 4) {
                    Text("Secret Key".localized)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(secretKey)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .onTapGesture {
                            UIPasteboard.general.string = secretKey
                        }
                }
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.horizontal)
            
            // Settings
            VStack(spacing: 0) {
                HStack {
                    Text("Issuer".localized)
                        .foregroundColor(.gray)
                    Spacer()
                    TextField("Issuer".localized, text: $issuer)
                        .multilineTextAlignment(.trailing)
                }
                .padding()
                
                Divider()
                
                HStack {
                    Text("Account".localized)
                        .foregroundColor(.gray)
                    Spacer()
                    TextField("Account".localized, text: $accountName)
                        .multilineTextAlignment(.trailing)
                }
                .padding()
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
            .padding(.horizontal)
            
            // Actions
            VStack(spacing: 16) {
                Button {
                    generateNewSecret()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Regenerate Secret".localized)
                    }
                    .font(.headline)
                    .foregroundColor(Theme.primary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
                
                Button {
                    saveToKeyBox()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.down.fill")
                        Text("Save to KeyBox".localized)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.primaryGradient)
                    .clipShape(Capsule())
                    .shadow(color: Theme.shadowColor, radius: 10, x: 0, y: 5)
                }
            }
            .padding(.horizontal)
            
            Spacer()
                .frame(height: 120) // Increased to avoid blocking by TabBar
        }
        .onAppear {
            if secretKey.isEmpty {
                generateNewSecret()
            }
        }
        .onChange(of: issuer) { _, _ in updateQRCode() }
        .onChange(of: accountName) { _, _ in updateQRCode() }
        .alert("Saved".localized, isPresented: $showSavedAlert) {
            Button("OK".localized, role: .cancel) { }
        } message: {
            Text("Token has been saved to your KeyBox.".localized)
        }
    }
    
    func generateNewSecret() {
        secretKey = OTPGenerator.generateRandomSecret()
        updateQRCode()
    }
    
    func updateQRCode() {
        // Format: otpauth://totp/Issuer:Account?secret=SECRET&issuer=Issuer
        let issuerSafe = issuer.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let accountSafe = accountName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let label = "\(issuerSafe):\(accountSafe)"
        
        let string = "otpauth://totp/\(label)?secret=\(secretKey)&issuer=\(issuerSafe)"
        
        filter.message = Data(string.utf8)
        
        if let outputImage = filter.outputImage {
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                qrCodeImage = UIImage(cgImage: cgImage)
            }
        }
    }
    
    func saveToKeyBox() {
        TokenViewModel.shared.addToken(issuer: issuer, accountName: accountName, secret: secretKey)
        showSavedAlert = true
        // Optionally trigger a haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
