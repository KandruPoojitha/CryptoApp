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

                    if !isLoginMode {
                        inputField(image: "person", placeholder: "Name", text: $userName, isValid: !userName.isEmpty)
                    }
                    inputField(image: "mail", placeholder: "Email", text: $email, isValid: email.isValidEmail())
                    inputField(image: "lock", placeholder: "Password", text: $password, isSecure: true, isValid: isValidPassword(password))

                    if !isLoginMode {
                        inputField(image: "lock.fill", placeholder: "Confirm Password", text: $confirmPassword, isSecure: true, isValid: password == confirmPassword)
                    }

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

                    // Error Message
                    if !alertMessage.isEmpty {
                        Text(alertMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
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

    private func resetFields() {
        email = ""
        password = ""
        confirmPassword = ""
        userName = ""
    }

    private func loginUser() {
        guard email.isValidEmail() else {
            alertMessage = "Please enter a valid email address."
            return
        }
        
        guard isValidPassword(password) else {
            alertMessage = "Password must be at least 6 characters."
            return
        }

        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error as NSError? {
                switch AuthErrorCode(rawValue: error.code) {
                case .wrongPassword:
                    alertMessage = "The password you entered is incorrect. Please try again."
                case .invalidEmail:
                    alertMessage = "The email address format is invalid. Please check and try again."
                case .userNotFound:
                    alertMessage = "No account found with this email address. Please sign up."
                case .userDisabled:
                    alertMessage = "This account has been disabled. Contact support for assistance."
                default:
                    alertMessage = "An unexpected error occurred: \(error.localizedDescription)"
                }
                return
            }

            if let authResult = authResult {
                withAnimation {
                    userID = authResult.user.uid
                    navigateToHomeView = true
                }
            }
        }
    }

    private func registerUser() {
        if userName.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty {
            alertMessage = "Please fill all fields to sign up."
            return
        }

        guard email.isValidEmail() else {
            alertMessage = "Please enter a valid email address."
            return
        }
        
        guard isValidPassword(password) else {
            alertMessage = "Password must be at least 6 characters."
            return
        }
        
        guard password == confirmPassword else {
            alertMessage = "Passwords do not match."
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                alertMessage = error.localizedDescription
                return
            }

            if let authResult = authResult {
                let ref = Database.database().reference().child("users").child(authResult.user.uid)
                ref.setValue(["name": userName, "email": email, "balance": 0.0])

                withAnimation {
                    userID = authResult.user.uid
                    isAccountCreated = true
                    alertMessage = ""
                }
            }
        }
    }

    private func sendPasswordReset() {
        guard email.isValidEmail() else {
            alertMessage = "Please enter a valid email address."
            return
        }

        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                alertMessage = error.localizedDescription
            } else {
                alertMessage = "A password reset link has been sent to your email."
            }
        }
    }

    private func isValidPassword(_ password: String) -> Bool {
        return password.count >= 6
    }
}
