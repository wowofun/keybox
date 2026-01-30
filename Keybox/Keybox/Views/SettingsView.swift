import SwiftUI
import PhotosUI

struct SettingsView: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @ObservedObject private var biometricManager = BiometricManager.shared
    @ObservedObject private var cloudManager = CloudSyncManager.shared
    @ObservedObject private var userProfile = UserProfileManager.shared
    @ObservedObject private var recommendationService = RecommendationService.shared
    @ObservedObject private var notificationManager = NotificationManager.shared
    
    @State private var showResetConfirmation = false
    @State private var showResetSuccess = false
    @State private var showCopySuccess = false
    @State private var showEditNickname = false
    @State private var tempNickname = ""
    @State private var selectedItem: PhotosPickerItem? = nil
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("User".localized)) {
                    HStack(spacing: 16) {
                        // Avatar with PhotosPicker
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            ZStack {
                                if let avatar = userProfile.avatarImage {
                                    Image(uiImage: avatar)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .frame(width: 60, height: 60)
                                        .foregroundColor(Theme.primary.opacity(0.8))
                                }
                                
                                // Edit overlay hint
                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                                    .background(Circle().fill(Theme.primary))
                                    .offset(x: 20, y: 20)
                            }
                        }
                        .buttonStyle(.plain)
                        .onChange(of: selectedItem) { newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    userProfile.saveAvatar(image)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            // Nickname
                            HStack {
                                Text(userProfile.nickname)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                
                                Button {
                                    tempNickname = userProfile.nickname
                                    showEditNickname = true
                                } label: {
                                    Image(systemName: "square.and.pencil")
                                        .font(.caption)
                                        .foregroundColor(Theme.primary)
                                }
                            }
                            
                            // User Type Badge
                            HStack(spacing: 4) {
                                Image(systemName: "crown.fill")
                                    .font(.caption2)
                                Text(userProfile.memberType.localized)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(LinearGradient(
                                        colors: [Color.yellow.opacity(0.3), Color.orange.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                            )
                            .foregroundColor(.orange)
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.orange.opacity(0.5), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
                .alert("Edit Nickname".localized, isPresented: $showEditNickname) {
                    TextField("Enter new nickname".localized, text: $tempNickname)
                    Button("Cancel".localized, role: .cancel) { }
                    Button("Save".localized) {
                        if !tempNickname.isEmpty {
                            userProfile.nickname = tempNickname
                        }
                    }
                }
                
                Section(header: Text("Security".localized)) {
                    Toggle(isOn: $biometricManager.isFaceIDEnabled) {
                        Label {
                            Text("Face ID".localized)
                        } icon: {
                            Image(systemName: "faceid")
                                .foregroundColor(Theme.primary)
                        }
                    }
                    .tint(Theme.primary)
                    .onChange(of: biometricManager.isFaceIDEnabled) { _, newValue in
                        if newValue {
                            biometricManager.authenticate()
                        }
                        NotificationManager.shared.addNotification(
                            type: .security,
                            title: "Security Alert".localized,
                            message: newValue ? "Face ID Enabled".localized : "Face ID Disabled".localized
                        )
                    }
                    
                    Toggle(isOn: Binding(
                        get: { cloudManager.isCloudSyncEnabled },
                        set: { newValue in
                            let updateState = {
                                cloudManager.isCloudSyncEnabled = newValue
                                NotificationManager.shared.addNotification(
                                    type: .sync,
                                    title: "Cloud Sync".localized,
                                    message: newValue ? "iCloud Sync Enabled".localized : "iCloud Sync Disabled".localized
                                )
                            }
                            
                            // Intercept toggle change to require authentication
                            if biometricManager.isFaceIDEnabled {
                                BiometricManager.shared.authenticateAction(reason: "Authenticate to toggle iCloud Sync".localized) { success in
                                    if success {
                                        updateState()
                                    }
                                }
                            } else {
                                // No FaceID, allow toggle directly
                                updateState()
                            }
                        }
                    )) {
                        Label {
                            Text("iCloud Backup".localized)
                        } icon: {
                            Image(systemName: "icloud")
                                .foregroundColor(Theme.primary)
                        }
                    }
                    .tint(Theme.primary)
                    
                    if let lastSync = cloudManager.lastSyncDate {
                        Text(String(format: "Last Backup: %@".localized, lastSync.formatted()))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("General".localized)) {
                    NavigationLink {
                        TutorialListView()
                    } label: {
                        Label {
                            Text("Usage Tutorial".localized)
                        } icon: {
                            Image(systemName: "book.fill")
                                .foregroundColor(.blue)
                        }
                    }

                    NavigationLink {
                        NotificationListView()
                    } label: {
                        HStack {
                            Label {
                                Text("Notifications".localized)
                            } icon: {
                                Image(systemName: "bell.badge")
                                    .foregroundColor(.red)
                            }
                            
                            Spacer()
                            
                            if notificationManager.unreadCount > 0 {
                                Text("\(notificationManager.unreadCount)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.red))
                            }
                        }
                    }
                    
                    // Language Picker
                    Picker(selection: $localizationManager.language) {
                        ForEach(Language.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    } label: {
                        Label {
                            Text("Language".localized)
                        } icon: {
                            Image(systemName: "globe")
                                .foregroundColor(Theme.primary)
                        }
                    }
                }
                
                // Recommended Apps
                if !recommendationService.apps.isEmpty {
                    Section(header: Text("Recommended Apps".localized)) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                ForEach(recommendationService.apps) { app in
                                    Button {
                                        if let urlString = app.url, let url = URL(string: urlString) {
                                            UIApplication.shared.open(url)
                                        }
                                    } label: {
                                        VStack(spacing: 8) {
                                            AsyncImage(url: URL(string: app.icon)) { phase in
                                                switch phase {
                                                case .empty:
                                                    ProgressView()
                                                        .frame(width: 60, height: 60)
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 60, height: 60)
                                                        .cornerRadius(12)
                                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                                case .failure:
                                                    Image(systemName: "app.dashed")
                                                        .resizable()
                                                        .frame(width: 60, height: 60)
                                                        .foregroundColor(.gray)
                                                @unknown default:
                                                    EmptyView()
                                                }
                                            }
                                            
                                            Text(app.name)
                                                .font(.caption)
                                                .foregroundColor(.primary)
                                                .lineLimit(1)
                                                .frame(width: 70)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 0))
                    }
                }
                
                // Community
                Section(header: Text("Community".localized)) {
                    // X
                    Link(destination: URL(string: "https://x.com/ID8fun")!) {
                        HStack {
                            Label {
                                Text("Official X".localized)
                            } icon: {
                                Image(systemName: "globe") // System icon for web/X
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                    
                    // XiaoHongShu
                    Link(destination: URL(string: "https://xhslink.com/m/1271o7GPBFJ")!) {
                        HStack {
                            Label {
                                Text("Official XiaoHongShu".localized)
                            } icon: {
                                Image(systemName: "book.closed.fill")
                                    .foregroundColor(.red)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                    
                    // QQ Group
                    Button {
                        UIPasteboard.general.string = "874492540"
                        showCopySuccess = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showCopySuccess = false
                        }
                    } label: {
                        HStack {
                            Label {
                                Text("Join QQ Group".localized)
                            } icon: {
                                Image(systemName: "person.3.fill")
                                    .foregroundColor(.blue)
                            }
                            Spacer()
                            Text("874492540")
                                .foregroundColor(.secondary)
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                    
                    // WeChat
                    Button {
                        UIPasteboard.general.string = "ID8FUN"
                        showCopySuccess = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showCopySuccess = false
                        }
                    } label: {
                        HStack {
                            Label {
                                Text("Copy WeChat ID".localized)
                            } icon: {
                                Image(systemName: "message.fill")
                                    .foregroundColor(.green)
                            }
                            Spacer()
                            Text("ID8FUN")
                                .foregroundColor(.secondary)
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }
                
                Section(header: Text("About".localized)) {
                    HStack {
                        Text("Version".localized)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
                
                /*
                Section(header: Text("Debug".localized)) {
                    Button("Force Cloud Upload".localized) {
                        cloudManager.sync(force: true)
                    }
                    Button("Force Cloud Restore".localized) {
                        cloudManager.forceRestoreFromCloud()
                    }
                }
                */
                
                Section {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Text("Reset All Data".localized)
                    }
                    .alert(isPresented: $showResetConfirmation) {
                        Alert(
                            title: Text("Reset Data".localized),
                            message: Text("This will delete all your keys and accounts. This action cannot be undone.".localized),
                            primaryButton: .destructive(Text("Confirm".localized)) {
                                if biometricManager.isFaceIDEnabled {
                                    BiometricManager.shared.authenticateAction(reason: "Authenticate to reset all data".localized) { success in
                                        if success {
                                            resetAllData()
                                        }
                                    }
                                } else {
                                    resetAllData()
                                }
                            },
                            secondaryButton: .cancel(Text("Cancel".localized))
                        )
                    }
                }
                
                Section {
                    Spacer()
                        .frame(height: 80)
                        .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Settings".localized)
            .alert(isPresented: $showResetSuccess) {
                 Alert(title: Text("Data Reset".localized), message: Text("All data has been successfully reset.".localized), dismissButton: .default(Text("OK".localized)))
            }
            .overlay(
                Group {
                    if showCopySuccess {
                        VStack {
                            Spacer()
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                                Text("Copied!".localized)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(Color.black.opacity(0.75)))
                            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                            .padding(.bottom, 60)
                            .transition(.scale.combined(with: .opacity))
                            .zIndex(100)
                        }
                        .animation(.spring(), value: showCopySuccess)
                    }
                }
            )
        }
    }
    
    private func resetAllData() {
        // Clear local data
        UserDefaults.standard.removeObject(forKey: "saved_tokens_v1")
        UserDefaults.standard.removeObject(forKey: "saved_accounts_v1")
        
        // Notify ViewModels to reload/clear
        NotificationCenter.default.post(name: Notification.Name("ResetAllData"), object: nil)
        
        NotificationManager.shared.addNotification(
            type: .security,
            title: "Data Reset".localized,
            message: "All data has been successfully reset.".localized
        )
        
        // Notify user
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showResetSuccess = true
        }
    }
}
