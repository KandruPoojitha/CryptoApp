import SwiftUI
import Firebase
import FirebaseAuth

struct LoginRegisterView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var alertMessage = ""
    @State private var isShowingAlert = false
    @State private var isLoginMode = true
    @State private var isAccountCreated = false
    @AppStorage("uid") var userID: String = ""
    @State private var navigateToHomeView = false
    @State private var isForgotPasswordAlert = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).edgesIgnoringSafeArea(.all)
                VStack {
                    Spacer()
                    HStack {
                        Text(isLoginMode ? "Welcome Back!" : "Create Account")
                            .font(.largeTitle)
                            .bold()
                            .opacity(1)
                            .scaleEffect(isLoginMode ? 0.8 : 0.8)
                            .animation(.spring(), value: isLoginMode)
                    }
                    .padding(.top)
                    Spacer()
                    inputField(image: "mail", placeholder: "Email", text: $email, isValid: email.isValidEmail())
                        .transition(.opacity.combined(with: .scale))
                    
                    inputField(image: "lock", placeholder: "Password", text: $password, isSecure: true, isValid: isValidPassword(password))
                        .transition(.opacity.combined(with: .scale))

                    if !isLoginMode {
                        inputField(image: "lock.fill", placeholder: "Confirm Password", text: $confirmPassword, isSecure: true, isValid: password == confirmPassword)
                            .transition(.opacity.combined(with: .scale))
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
                            .scaleEffect(isLoginMode ? 1 : 0.9)
                            .animation(.easeInOut, value: isLoginMode)
                    }
                    .padding()

                    Button(action: isLoginMode ? loginUser : registerUser) {
                        Text(isLoginMode ? "Sign In" : "Sign Up")
                            .foregroundColor(.black)
                            .font(.title3)
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white)) // White background in light mode
                            .scaleEffect(isLoginMode ? 1 : 1.1)
                            .animation(.easeInOut, value: isLoginMode)
                    }
                    .padding()
                    .alert(isPresented: $isShowingAlert) {
                        Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                    }
                    .alert(isPresented: $isAccountCreated) {
                        Alert(
                            title: Text("Success"),
                            message: Text("Account created successfully! Please log in."),
                            dismissButton: .default(Text("OK")) {
                                withAnimation {
                                    isLoginMode = true
                                    resetFields()
                                }
                            }
                        )
                    }
                    Spacer()
                }
                .padding()
                .background(
                    NavigationLink(destination: HomeView(), isActive: $navigateToHomeView) {
                        EmptyView()
                    }
                )
            }
        }
    }

    private func inputField(image: String, placeholder: String, text: Binding<String>, isSecure: Bool = false, isValid: Bool = false) -> some View {
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
    }

    private func resetFields() {
        email = ""
        password = ""
        confirmPassword = ""
    }

    private func loginUser() {
        guard email.isValidEmail() else {
            alertMessage = "Please enter a valid email address."
            isShowingAlert = true
            return
        }
        
        guard isValidPassword(password) else {
            alertMessage = "Password must be at least 6 characters."
            isShowingAlert = true
            return
        }

        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                alertMessage = error.localizedDescription
                isShowingAlert = true
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
        guard email.isValidEmail() else {
            alertMessage = "Please enter a valid email address."
            isShowingAlert = true
            return
        }
        
        guard isValidPassword(password) else {
            alertMessage = "Password must be at least 6 characters."
            isShowingAlert = true
            return
        }
        
        guard password == confirmPassword else {
            alertMessage = "Passwords do not match."
            isShowingAlert = true
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                alertMessage = error.localizedDescription
                isShowingAlert = true
                return
            }

            if let authResult = authResult {
                withAnimation {
                    userID = authResult.user.uid
                    isAccountCreated = true
                }
            }
        }
    }

    private func sendPasswordReset() {
        guard email.isValidEmail() else {
            alertMessage = "Please enter a valid email address."
            isShowingAlert = true
            return
        }

        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                alertMessage = error.localizedDescription
                isShowingAlert = true
            } else {
                alertMessage = "A password reset link has been sent to your email."
                isShowingAlert = true
            }
        }
    }
}

func isValidPassword(_ password: String) -> Bool {
    return password.count >= 6
}

struct LoginRegisterView_Previews: PreviewProvider {
    static var previews: some View {
        LoginRegisterView()
            .preferredColorScheme(.dark) // Set dark mode for the preview
    }
}
