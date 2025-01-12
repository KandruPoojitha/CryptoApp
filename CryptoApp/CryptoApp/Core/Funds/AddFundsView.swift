import SwiftUI
import Stripe
import FirebaseAuth
import FirebaseDatabase

struct AddFundsView: View {
    var stripeCustomerId: String // Stripe Customer ID passed from AccountView

    @State private var amount: String = ""
    @State private var selectedCardId: String = ""
    @State private var cards: [STPPaymentMethod] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Funds")
                .font(.largeTitle)
                .bold()

            TextField("Enter amount (USD)", text: $amount)
                .keyboardType(.decimalPad)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)

            if !cards.isEmpty {
                Picker("Select Card", selection: $selectedCardId) {
                    ForEach(cards, id: \.stripeId) { card in
                        Text("Card Ending in \(card.card?.last4 ?? "****")")
                            .tag(card.stripeId)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
            } else {
                Text("No cards available. Please add a card first.")
                    .foregroundColor(.red)
                    .font(.caption)
            }

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }

            Button(action: initiatePayment) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Add Funds")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(cards.isEmpty ? Color.gray : Color.green)
                        .cornerRadius(10)
                }
            }
            .disabled(isLoading || cards.isEmpty)

            Spacer()
        }
        .padding()
        .onAppear(perform: fetchCards)
    }

    private func fetchCards() {
        guard !stripeCustomerId.isEmpty else {
            errorMessage = "Stripe Customer ID is missing."
            return
        }

        isLoading = true
        errorMessage = nil

        let url = URL(string: "https://api.stripe.com/v1/payment_methods?customer=\(stripeCustomerId)&type=card")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer sk_test_51PlVh8P9Bz7XrwZPWSkDzX7AmaNgVr04yPOQWnbAECiYSWKtsmmVgD2Z8JYBY8a5dmEfKXaTewrBESb3fxIliwDo00HdJmKBKz", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Error fetching cards: \(error.localizedDescription)"
                    return
                }

                if let data = data,
                   let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let error = response["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        self.errorMessage = "Stripe Error: \(message)"
                        return
                    }

                    if let paymentMethods = response["data"] as? [[String: Any]] {
                        self.cards = paymentMethods.compactMap { STPPaymentMethod.decodedObject(fromAPIResponse: $0) }
                        if let firstCard = self.cards.first {
                            self.selectedCardId = firstCard.stripeId
                        }
                    } else {
                        self.errorMessage = "No payment methods found."
                    }
                } else {
                    self.errorMessage = "Error parsing response from Stripe."
                }
            }
        }.resume()
    }

    private func initiatePayment() {
        guard let amountInCents = Int(amount), amountInCents > 0 else {
            errorMessage = "Invalid amount."
            return
        }

        guard !selectedCardId.isEmpty else {
            errorMessage = "Please select a card."
            return
        }

        isLoading = true
        errorMessage = nil

        let url = URL(string: "https://api.stripe.com/v1/payment_intents")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer sk_test_51PlVh8P9Bz7XrwZPWSkDzX7AmaNgVr04yPOQWnbAECiYSWKtsmmVgD2Z8JYBY8a5dmEfKXaTewrBESb3fxIliwDo00HdJmKBKz", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = """
        amount=\(amountInCents * 100)&currency=usd&customer=\(stripeCustomerId)&payment_method=\(selectedCardId)&confirm=true&payment_method_types[]=card
        """.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Error creating payment: \(error.localizedDescription)"
                    return
                }

                if let data = data,
                   let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let error = jsonResponse["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        self.errorMessage = "Stripe Error: \(message)"
                        return
                    }

                    if let paymentStatus = jsonResponse["status"] as? String, paymentStatus == "succeeded" {
                        self.updateFirebaseBalance(amount: Double(amountInCents))
                    } else {
                        self.errorMessage = "Payment failed. Status: \(jsonResponse["status"] ?? "unknown")"
                    }
                } else {
                    self.errorMessage = "Error parsing response from Stripe."
                }
            }
        }.resume()
    }

    private func updateFirebaseBalance(amount: Double) {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let ref = Database.database().reference().child("users").child(userId)
        ref.child("balance").observeSingleEvent(of: .value) { snapshot in
            let currentBalance = snapshot.value as? Double ?? 0.0
            ref.child("balance").setValue(currentBalance + amount)
        }
    }
}
