import Foundation
import Combine
import SwiftUI

struct RecommendedApp: Codable, Identifiable {
    let id: Int
    let title: String
    let cover: String
    let external: String?
    
    // Computed properties for compatibility with existing view code
    var name: String { title }
    var icon: String { cover }
    var url: String? { external }
}

struct RecommendationResponse: Codable {
    let success: Bool
    let data: [RecommendedApp]?
    // let error: String? // API might not return error field in success case
}

class RecommendationService: ObservableObject {
    static let shared = RecommendationService()
    
    @Published var apps: [RecommendedApp] = []
    
    private let userDefaultsKey = "cached_recommended_apps"
    private let lastFetchDateKey = "last_apps_fetch_date"
    private let cacheDuration: TimeInterval = 24 * 60 * 60 // 24 hours
    
    init() {
        loadCachedApps()
        checkAndFetchApps()
    }
    
    private func loadCachedApps() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let cachedApps = try? JSONDecoder().decode([RecommendedApp].self, from: data) {
            self.apps = cachedApps
        }
    }
    
    func checkAndFetchApps() {
        let lastFetch = UserDefaults.standard.object(forKey: lastFetchDateKey) as? Date ?? Date.distantPast
        
        if Date().timeIntervalSince(lastFetch) > cacheDuration {
            fetchApps()
        }
    }
    
    func fetchApps() {
        guard let url = URL(string: "https://api.id8.fun/api/public/apps") else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                print("Failed to fetch apps: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                let result = try JSONDecoder().decode(RecommendationResponse.self, from: data)
                if result.success, let newApps = result.data {
                    DispatchQueue.main.async {
                        self?.apps = newApps
                        self?.saveAppsToCache(newApps)
                    }
                } else {
                    print("API Error: Failed to fetch data")
                }
            } catch {
                print("Decoding error: \(error)")
                // Try decoding as plain array if wrapper fails, just in case
                if let appsArray = try? JSONDecoder().decode([RecommendedApp].self, from: data) {
                    DispatchQueue.main.async {
                        self?.apps = appsArray
                        self?.saveAppsToCache(appsArray)
                    }
                }
            }
        }.resume()
    }
    
    private func saveAppsToCache(_ apps: [RecommendedApp]) {
        if let encoded = try? JSONEncoder().encode(apps) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            UserDefaults.standard.set(Date(), forKey: lastFetchDateKey)
        }
    }
}
