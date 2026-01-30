import Foundation
import Combine
import SwiftUI

enum NotificationType: String, Codable {
    case add
    case delete
    case update
    case view // Specifically for viewing secrets
    case sync // For cloud sync/backup
    case security // For FaceID/Settings changes
    case system // For system alerts if needed
    
    var icon: String {
        switch self {
        case .add: return "plus.circle.fill"
        case .delete: return "trash.circle.fill"
        case .update: return "pencil.circle.fill"
        case .view: return "eye.circle.fill"
        case .sync: return "arrow.triangle.2.circlepath.circle.fill"
        case .security: return "lock.circle.fill"
        case .system: return "exclamationmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .add: return .green
        case .delete: return .red
        case .update: return .orange
        case .view: return .blue
        case .sync: return .blue
        case .security: return .purple
        case .system: return .gray
        }
    }
}

struct AppNotification: Identifiable, Codable {
    var id: UUID = UUID()
    let type: NotificationType
    let title: String
    let message: String
    let date: Date
    var isRead: Bool = false
}

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    
    private let userDefaultsKey = "app_notifications_v1"
    
    init() {
        loadNotifications()
    }
    
    func addNotification(type: NotificationType, title: String, message: String) {
        let notification = AppNotification(
            type: type,
            title: title,
            message: message,
            date: Date(),
            isRead: false
        )
        
        // Add to beginning of list
        notifications.insert(notification, at: 0)
        
        // Keep only last 100 notifications to prevent bloat
        if notifications.count > 100 {
            notifications = Array(notifications.prefix(100))
        }
        
        updateUnreadCount()
        saveNotifications()
    }
    
    func markAllAsRead() {
        for i in 0..<notifications.count {
            notifications[i].isRead = true
        }
        updateUnreadCount()
        saveNotifications()
    }
    
    func deleteNotification(at indexSet: IndexSet) {
        notifications.remove(atOffsets: indexSet)
        updateUnreadCount()
        saveNotifications()
    }
    
    private func updateUnreadCount() {
        unreadCount = notifications.filter { !$0.isRead }.count
    }
    
    private func saveNotifications() {
        if let encoded = try? JSONEncoder().encode(notifications) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadNotifications() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([AppNotification].self, from: data) {
            self.notifications = decoded
            updateUnreadCount()
        }
    }
}
