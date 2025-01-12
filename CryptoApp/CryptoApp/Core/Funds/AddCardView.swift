import SwiftUI
import Stripe

struct AddCardView: View {
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @Environment(\.presentationMode) var presentationMode
    var stripeCustomerId: String
    var onCardAdded: () -> Void

    @State private var paymentCardTextField = STPPaymentCardTextField()

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Card")
                .font(.largeTitle)
                .bold()

            CardInputField(cardTextField: $paymentCardTextField)
                .padding()

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button(action: addCard) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Add Card")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .disabled(isLoading)

            Spacer()
        }
        .padding()
    }

    private func addCard() {
        guard paymentCardTextField.isValid else {
            errorMessage = "Invalid card details."
            return
        }

        isLoading = true
        errorMessage = nil

        let paymentMethodParams = STPPaymentMethodParams(
            card: paymentCardTextField.cardParams,
            billingDetails: nil,
            metadata: nil
        )

        STPAPIClient.shared.createPaymentMethod(with: paymentMethodParams) { paymentMethod, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Error creating PaymentMethod: \(error.localizedDescription)"
                    return
                }

                if let paymentMethodId = paymentMethod?.stripeId {
                    self.attachPaymentMethodToCustomer(paymentMethodId: paymentMethodId)
                }
            }
        }
    }

    private func attachPaymentMethodToCustomer(paymentMethodId: String) {
        isLoading = true

        let attachURL = URL(string: "https://api.stripe.com/v1/payment_methods/\(paymentMethodId)/attach")!
        var request = URLRequest(url: attachURL)
        request.httpMethod = "POST"
        request.setValue("Bearer sk_test_51PlVh8P9Bz7XrwZPWSkDzX7AmaNgVr04yPOQWnbAECiYSWKtsmmVgD2Z8JYBY8a5dmEfKXaTewrBESb3fxIliwDo00HdJmKBKz", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyString = "customer=\(stripeCustomerId)"
        request.httpBody = bodyString.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Error attaching card: \(error.localizedDescription)"
                    return
                }

                // Safely unwrap the `data`
                guard let data = data else {
                    self.errorMessage = "No response data received from Stripe."
                    return
                }

                // Process JSON response
                if let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let _ = jsonResponse["id"] as? String {
                    self.onCardAdded() // Notify the parent view
                    self.presentationMode.wrappedValue.dismiss()
                } else if let errorDetails = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any],
                          let error = errorDetails["error"] as? [String: Any],
                          let message = error["message"] as? String {
                    self.errorMessage = message
                } else {
                    self.errorMessage = "Unexpected response while attaching card."
                }
            }
        }.resume()
    }
}

struct CardInputField: UIViewRepresentable {
    @Binding var cardTextField: STPPaymentCardTextField

    func makeUIView(context: Context) -> STPPaymentCardTextField {
        return cardTextField
    }

    func updateUIView(_ uiView: STPPaymentCardTextField, context: Context) {}
}
