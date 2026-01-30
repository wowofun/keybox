import SwiftUI

struct TutorialListView: View {
    var body: some View {
        List {
            Section(header: Text("2FA / TOTP".localized)) {
                NavigationLink("How to add 2FA account?".localized) {
                    TutorialDetailView(
                        title: "How to add 2FA account?".localized,
                        content: "tutorial_add_2fa_content".localized
                    )
                }
            }
            
            Section(header: Text("Account Box".localized)) {
                NavigationLink("How to use Password Box?".localized) {
                     TutorialDetailView(
                        title: "How to use Password Box?".localized,
                        content: "tutorial_password_box_content".localized
                    )
                }
                NavigationLink("How to generate password?".localized) {
                    TutorialDetailView(
                        title: "How to generate password?".localized,
                        content: "tutorial_password_gen_content".localized
                    )
                }
            }
            
            Section(header: Text("Security & Backup".localized)) {
                 NavigationLink("How to backup data?".localized) {
                     TutorialDetailView(
                        title: "How to backup data?".localized,
                        content: "tutorial_backup_content".localized
                    )
                }
                NavigationLink("How to use Face ID?".localized) {
                    TutorialDetailView(
                        title: "How to use Face ID?".localized,
                        content: "tutorial_faceid_content".localized
                    )
                }
            }
        }
        .navigationTitle("Usage Tutorial".localized)
    }
}

struct TutorialDetailView: View {
    let title: String
    let content: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(content)
                    .font(.body)
                    .lineSpacing(6)
            }
            .padding()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
