import Foundation
import SwiftUI
import Combine

class UserProfileManager: ObservableObject {
    static let shared = UserProfileManager()
    
    @AppStorage("user_nickname") var nickname: String = "User"
    @AppStorage("user_member_type") var memberType: String = "Pro Member" // Can be "Pro Member", "Free Member", etc.
    
    @Published var avatarImage: UIImage?
    
    private let avatarFileName = "user_avatar.png"
    
    init() {
        loadAvatar()
    }
    
    func saveAvatar(_ image: UIImage) {
        self.avatarImage = image
        if let data = image.pngData() {
            let url = getDocumentsDirectory().appendingPathComponent(avatarFileName)
            try? data.write(to: url)
        }
    }
    
    func loadAvatar() {
        let url = getDocumentsDirectory().appendingPathComponent(avatarFileName)
        if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
            self.avatarImage = image
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
