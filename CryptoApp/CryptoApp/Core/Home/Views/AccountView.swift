import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct AccountView: View {
    @State private var userName: String = "John Doe"
    @State private var userEmail: String = "john.doe@example.com"
    @State private var walletBalance: Double = 0.0
    @State private var stripeCustomerId: String = ""
    @State private var isLoggedOut: Bool = false
    @State private var showResetToast: Bool = false
    @State private var isEditingProfile: Bool = false 
    @State private var updatedUserName: String = ""
    @State private var updatedUserEmail: String = ""

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
                    .sheet(isPresented: $isEditingProfile) {
                        editProfileSheet
                    }
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

            Button(action: {
                // Enable edit mode and set current values
                updatedUserName = userName
                updatedUserEmail = userEmail
                isEditingProfile.toggle()
            }) {
                Image(systemName: "pencil")
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
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

    // MARK: - Edit Profile Sheet
    private var editProfileSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Username", text: $updatedUserName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                TextField("Email", text: $updatedUserEmail)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button(action: {
                    saveProfileChanges()
                }) {
                    Text("Save Changes")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .navigationTitle("Edit Profile")
            .navigationBarItems(leading: Button("Cancel") {
                isEditingProfile = false
            })
        }
    }

    // MARK: - Transaction History Button
    private var transactionHistoryButton: some View {
        NavigationLink(destination: TransactionHistoryView()) {
            accountOptionRow(title: "Transaction History", icon: "clock")
        }
    }

    // MARK: - Funds Transaction History Button
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

    // MARK: - Logout Button
    private var logoutButton: some View {
        Button(action: logoutUser) {
            Text("Log Out")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }

    // MARK: - Save Profile Changes
    private func saveProfileChanges() {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        let ref = Database.database().reference().child("users").child(userID)
        ref.updateChildValues(["name": updatedUserName, "email": updatedUserEmail]) { error, _ in
            if let error = error {
                print("Error updating profile: \(error.localizedDescription)")
                return
            }

            // Update local state
            userName = updatedUserName
            userEmail = updatedUserEmail
            isEditingProfile = false
        }
    }

    // MARK: - Send Reset Password Link
    private func sendResetPasswordLink() {
        Auth.auth().sendPasswordReset(withEmail: userEmail) { error in
            if let error = error {
                print("Error sending reset password link: \(error.localizedDescription)")
                return
            }
            showResetToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showResetToast = false
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

    // MARK: - Fetch User Data
    private func fetchUserData() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("users").child(userID)

        ref.observeSingleEvent(of: .value) { snapshot in
            if let userData = snapshot.value as? [String: Any] {
                self.userName = userData["name"] as? String ?? "Unknown User"
                self.userEmail = userData["email"] as? String ?? "unknown@example.com"
                self.walletBalance = userData["balance"] as? Double ?? 0.0
                self.stripeCustomerId = userData["stripeCustomerId"] as? String ?? ""
            } else {
                print("Error: User data not found in Firebase.")
            }
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
                        .transition(.opacity)
                        .animation(.easeInOut, value: isShowing.wrappedValue)
                }
            }
        }
    }
}
