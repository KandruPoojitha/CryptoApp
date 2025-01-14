import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct AccountView: View {
    @State private var userName: String = "John Doe"
    @State private var userEmail: String = "john.doe@example.com"
    @State private var walletBalance: Double = 0.0
    @State private var stripeCustomerId: String = "" // Store Stripe Customer ID
    @State private var isLoggedOut: Bool = false // State to track logout status
    @State private var showResetToast: Bool = false // Show reset password toast

    var body: some View {
        NavigationView {
            VStack {
                if isLoggedOut {
                    NavigationLink(destination: LoginRegisterView(), isActive: $isLoggedOut) {
                        EmptyView()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Profile Section
                            profileSection

                            // Wallet Balance Section
                            walletBalanceSection
                        
                            // Transaction History Buttons
                            transactionHistoryButton
                            fundstransactionHistoryButton

                            // Account Options
                            accountOptionsSection

                            // Reset Password Button
                            resetPasswordButton

                            // Logout Button
                            logoutButton
                        }
                        .padding()
                    }
                    .navigationTitle("Account")
                    .onAppear {
                        fetchUserData()
                    }
                    .toast(isShowing: $showResetToast, message: "Password reset link sent to \(userEmail).")
                }
            }
        }
    }

    // MARK: - Profile Section
    private var profileSection: some View {
        HStack(spacing: 20) {
            Image(systemName: "person.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 5) {
                Text(userName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(userEmail)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }

    // MARK: - Wallet Balance Section
    private var walletBalanceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Wallet Balance")
                .font(.headline)
                .foregroundColor(.primary)

            HStack {
                Text("$\(walletBalance, specifier: "%.2f")")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.green)

                Spacer()

                if !stripeCustomerId.isEmpty {
                    NavigationLink(destination: AddFundsView(stripeCustomerId: stripeCustomerId)) {
                        Text("Add Funds")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                } else {
                    Text("Loading...")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }

    // MARK: - Transaction History Button
    private var fundstransactionHistoryButton: some View {
        NavigationLink(destination: FundsTransactionHistoryView()) {
            accountOptionRow(title: "Funds Transaction History", icon: "clock")
        }
    }

    // MARK: - Account Options Section
    private var accountOptionsSection: some View {
        VStack(spacing: 20) {
            NavigationLink(destination: ManageCardsView(stripeCustomerId: stripeCustomerId)) {
                accountOptionRow(title: "Manage Cards", icon: "creditcard")
            }
        }
    }

    private func accountOptionRow(title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color.blue)

            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(Color.gray)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }

    // MARK: - Transaction History Button
    private var transactionHistoryButton: some View {
        NavigationLink(destination: TransactionHistoryView()) {
            accountOptionRow(title: "Transaction History", icon: "clock")
        }
    }

    // MARK: - Reset Password Button
    private var resetPasswordButton: some View {
        Button(action: sendResetPasswordLink) {
            Text("Reset Password")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }

    private var logoutButton: some View {
        Button(action: {
            logoutUser()
        }) {
            Text("Log Out")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }

    // MARK: - Fetch User Data
    private func fetchUserData() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is logged in.")
            return
        }
        let ref = Database.database().reference().child("users").child(userID)

        ref.observeSingleEvent(of: .value) { snapshot in
            if let userData = snapshot.value as? [String: Any] {
                self.userName = userData["name"] as? String ?? "Unknown User"
                self.userEmail = userData["email"] as? String ?? "unknown@example.com"
                self.walletBalance = userData["balance"] as? Double ?? 0.0
                self.stripeCustomerId = userData["stripeCustomerId"] as? String ?? ""

                // If stripeCustomerId is empty, create a new Stripe customer
                if self.stripeCustomerId.isEmpty {
                    self.createStripeCustomer()
                }
            } else {
                print("Error: User data not found in Firebase.")
            }
        }
    }

    // MARK: - Create Stripe Customer
    private func createStripeCustomer() {
        let url = URL(string: "http://localhost:3000/create-customer")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "email": userEmail,
            "name": userName
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error creating Stripe customer: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let customerId = json["customerId"] as? String {
                self.stripeCustomerId = customerId

                // Save to Firebase
                if let userID = Auth.auth().currentUser?.uid {
                    let ref = Database.database().reference().child("users").child(userID)
                    ref.updateChildValues(["stripeCustomerId": customerId])
                }
            }
        }.resume()
    }

    // MARK: - Send Reset Password Link
    private func sendResetPasswordLink() {
        Auth.auth().sendPasswordReset(withEmail: userEmail) { error in
            if error == nil {
                showResetToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showResetToast = false
                }
            } else {
                print("Error sending reset password link.")
            }
        }
    }

    // MARK: - Logout User
    private func logoutUser() {
        do {
            try Auth.auth().signOut()
            print("User logged out successfully.")
            isLoggedOut = true
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}

// MARK: - Toast Modifier
extension View {
    func toast(isShowing: Binding<Bool>, message: String) -> some View {
        ZStack {
            self
            if isShowing.wrappedValue {
                VStack {
                    Spacer()
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(8)
                        .padding(.bottom, 20)
                }
                .transition(.opacity)
                .animation(.easeInOut, value: isShowing.wrappedValue)
            }
        }
    }
}

// MARK: - Preview
struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView()
    }
}
