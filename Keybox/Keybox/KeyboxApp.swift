//
//  KeyboxApp.swift
//  Keybox
//
//  Created by Rowan on 2026/1/28.
//

import SwiftUI

@main
struct KeyboxApp: App {
    @StateObject private var biometricManager = BiometricManager.shared
    @Environment(\.scenePhase) var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if biometricManager.isUnlocked {
                    TabBarView()
                        .preferredColorScheme(.light)
                        .tint(Theme.primary)
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Theme.primary)
                        
                        Text("Keybox Locked".localized)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Button(action: {
                            biometricManager.authenticate()
                        }) {
                            Text("Unlock with Face ID".localized)
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(width: 200)
                                .background(Theme.primaryGradient)
                                .cornerRadius(10)
                        }
                    }
                }
            }
            .onAppear {
                biometricManager.authenticate()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background {
                    biometricManager.isUnlocked = false
                }
            }
        }
    }
}
