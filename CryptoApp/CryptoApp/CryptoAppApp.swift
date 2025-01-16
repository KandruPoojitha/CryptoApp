import SwiftUI
import Firebase
import Stripe
@main
struct CrtptoAppApp: App {
    @StateObject var vm = HomeViewModel()
    @State private var showLaunchView = true
    init() {
        FirebaseApp.configure()
        StripeAPI.defaultPublishableKey = "pk_test_51PlVh8P9Bz7XrwZPnWMN2upZk3x00s3soZgJgM5QTMuwCNoZPBdGtmPRXB29vBnFvOXjEAv2vntLuQaWbPpEHOmP00D7pelv0B"
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
