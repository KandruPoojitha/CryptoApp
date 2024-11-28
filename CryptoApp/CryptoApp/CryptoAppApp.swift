import SwiftUI
import Firebase

@main
struct CrtptoAppApp: App {
    @StateObject var vm = HomeViewModel()
    @State private var showLaunchView = true
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            NavigationView {
                if showLaunchView {
                    LaunchView(showLaunchView: $showLaunchView)
                } else {
                    LoginRegisterView()
                }
            }
            .environmentObject(vm)
            .preferredColorScheme(.dark)
        }
    }
}
