import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct LoginRegisterView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var alertMessage: String = ""
    @State private var isLoginMode: Bool = true
    @State private var isAccountCreated: Bool = false
    @State private var userName: String = ""
    @AppStorage("uid") var userID: String = ""
    @State private var navigateToHomeView: Bool = false
    @State private var isForgotPasswordAlert: Bool = false
    @State private var showAlertMessage: Bool = false // Tracks whether to show the alert

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).edgesIgnoringSafeArea(.all)
                VStack {
                    Spacer()

                    Text(isLoginMode ? "Welcome Back!" : "Create Account")
                        .font(.largeTitle)
                        .bold()
                        .padding(.top)

                    Spacer()

                    // Input Fields
                    if !isLoginMode {
                        inputField(image: "person", placeholder: "Name", text: $userName, isValid: !userName.isEmpty)
                    }
                    inputField(image: "mail", placeholder: "Email", text: $email, isValid: email.isValidEmail())
                    inputField(image: "lock", placeholder: "Password", text: $password, isSecure: true, isValid: isValidPassword(password))

                    if !isLoginMode {
                        inputField(image: "lock.fill", placeholder: "Confirm Password", text: $confirmPassword, isSecure: true, isValid: password == confirmPassword)
                    }

                    // Forgot Password
                    if isLoginMode {
                        Button("Forgot Password?") {
                            isForgotPasswordAlert = true
                        }
                        .foregroundColor(.blue)
                        .padding()
                        .alert("Reset Password", isPresented: $isForgotPasswordAlert) {
                            TextField("Enter your email", text: $email)
                            Button("Send Reset Link") {
                                sendPasswordReset()
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("We'll send a password reset link to your email.")
                        }
                    }

                    // Toggle Login/Register
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            isLoginMode.toggle()
                            resetFields()
                        }
                    }) {
                        Text(isLoginMode ? "Don't have an account?" : "Already have an account?")
                            .foregroundColor(.secondary)
                    }
                    .padding()

                    // Login/Register Button
                    Button(action: isLoginMode ? loginUser : registerUser) {
                        Text(isLoginMode ? "Sign In" : "Sign Up")
                            .foregroundColor(.white)
                            .font(.title3)
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue))
                    }
                    .padding()

                    // Alert Message
                    if showAlertMessage {
                        Text(alertMessage)
                            .foregroundColor(alertMessage.contains("successfully") ? .green : .red) // Green for success
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .onAppear {
                                // Hide alert after 3 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    showAlertMessage = false
                                }
                            }
                    }

                    Spacer()
                }
                .padding()
                .background(
                    NavigationLink(destination: MainTabView(), isActive: $navigateToHomeView) {
                        EmptyView()
                    }
                )
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Input Field
    private func inputField(image: String, placeholder: String, text: Binding<String>, isSecure: Bool = false, isValid: Bool = false) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: image)
                if isSecure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                }
                Spacer()
                if text.wrappedValue.count != 0 {
                    Image(systemName: isValid ? "checkmark" : "xmark")
                        .fontWeight(.bold)
                        .foregroundColor(isValid ? .green : .red)
                }
            }
            .padding()
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(lineWidth: 2).foregroundColor(Color.secondary))
            .padding(.horizontal)
            
            if !isValid && text.wrappedValue.count != 0 {
                Text(validationMessage(for: placeholder))
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
        }
    }

    // MARK: - Helper Functions
    private func resetFields() {
        email = ""
        password = ""
        confirmPassword = ""
        userName = ""
    }

    private func validationMessage(for field: String) -> String {
        switch field {
        case "Email":
            return "Please enter a valid email address."
        case "Password":
            return "Password must be at least 6 characters."
        case "Confirm Password":
            return "Passwords do not match."
        case "Name":
            return "Name cannot be empty."
        default:
            return ""
        }
    }

    private func isValidPassword(_ password: String) -> Bool {
        return password.count >= 6
    }

    // MARK: - Firebase Functions
    private func loginUser() {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !normalizedEmail.isEmpty, !password.isEmpty else {
            showAlert("Please fill in all fields to sign in.")
            return
        }

        Auth.auth().signIn(withEmail: normalizedEmail, password: password) { authResult, error in
            if let error = error {
                showAlert(error.localizedDescription)
                return
            }

            if let user = authResult?.user {
                userID = user.uid
                navigateToHomeView = true
            }
        }
    }

    private func registerUser() {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if userName.isEmpty || normalizedEmail.isEmpty || password.isEmpty || confirmPassword.isEmpty {
            showAlert("Please fill all fields to sign up.")
            return
        }

        guard normalizedEmail.isValidEmail() else {
            showAlert("Please enter a valid email address.")
            return
        }

        guard isValidPassword(password) else {
            showAlert("Password must be at least 6 characters.")
            return
        }

        guard password == confirmPassword else {
            showAlert("Passwords do not match.")
            return
        }

        Auth.auth().createUser(withEmail: normalizedEmail, password: password) { authResult, error in
            if let error = error as NSError?, let errorCode = AuthErrorCode(rawValue: error.code) {
                switch errorCode {
                case .emailAlreadyInUse:
                    showAlert("The email address is already in use by another account.")
                default:
                    showAlert(error.localizedDescription)
                }
                return
            }

            if let authResult = authResult {
                let ref = Database.database().reference().child("users").child(authResult.user.uid)
                ref.setValue(["name": userName, "email": normalizedEmail, "balance": 0.0]) { error, _ in
                    if let error = error {
                        showAlert("Failed to save user data: \(error.localizedDescription)")
                        return
                    }

                    // Display success message and switch to login mode
                    showAlert("Account created successfully! Please log in.")
                    withAnimation {
                        isLoginMode = true
                        resetFields()
                    }
                }
            }
        }
    }

    private func sendPasswordReset() {
        guard email.isValidEmail() else {
            showAlert("Please enter a valid email address.")
            return
        }

        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                showAlert(error.localizedDescription)
                return
            }
            showAlert("Password reset email sent.")
        }
    }

    private func showAlert(_ message: String) {
        alertMessage = message
        showAlertMessage = true
    }
}
