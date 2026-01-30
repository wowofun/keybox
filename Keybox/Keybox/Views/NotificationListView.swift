import SwiftUI

struct NotificationListView: View {
    @ObservedObject var notificationManager = NotificationManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Navigation Bar
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Settings".localized)
                    }
                    .foregroundColor(Theme.primary)
                    .font(.system(size: 17))
                }
                
                Spacer()
                
                Text("Notifications".localized)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if notificationManager.unreadCount > 0 {
                    Button(action: {
                        withAnimation {
                            notificationManager.markAllAsRead()
                        }
                    }) {
                        Text("Read All".localized)
                            .font(.system(size: 17))
                            .foregroundColor(Theme.primary)
                    }
                } else {
                    // Placeholder for alignment
                    Text("Read All".localized)
                        .font(.system(size: 17))
                        .foregroundColor(.clear)
                }
            }
            .padding()
            .background(Color(UIColor.systemGroupedBackground))
            
            if notificationManager.notifications.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.3))
                    Text("No Notifications".localized)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemGroupedBackground))
            } else {
                List {
                    ForEach(notificationManager.notifications) { notification in
                        ZStack {
                            NavigationLink(destination: NotificationDetailView(notification: notification)) {
                                EmptyView()
                            }
                            .opacity(0)
                            
                            HStack(alignment: .top, spacing: 12) {
                                // Icon
                                Image(systemName: notification.type.icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(notification.type.color)
                                    .frame(width: 40, height: 40)
                                    .background(notification.type.color.opacity(0.1))
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(notification.title.localized)
                                            .font(.headline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        Text(formatDate(notification.date))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Text(notification.message)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .lineLimit(2)
                                    
                                    if notification.associatedID != nil {
                                        Text("Tap to restore".localized)
                                            .font(.caption)
                                            .foregroundColor(Theme.primary)
                                            .padding(.top, 2)
                                    }
                                }
                                
                                if !notification.isRead {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 8)
                                        .padding(.top, 6)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .onDelete(perform: notificationManager.deleteNotification)
                }
                .listStyle(InsetGroupedListStyle())
                .padding(.bottom, 80) // Add padding to avoid blockage by custom tab bar
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationBarHidden(true)
        .onAppear {
            // Optional: Auto-mark as read when viewing list? 
            // User requested "全部查看操作" (Read All action), so manual trigger is better.
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else if Calendar.current.isDateInYesterday(date) {
            formatter.dateFormat = "'\("Yesterday".localized)' HH:mm"
        } else {
            formatter.dateFormat = "MM-dd HH:mm"
        }
        return formatter.string(from: date)
    }
}
