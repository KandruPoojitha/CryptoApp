import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct Transaction: Identifiable, Hashable {
    let id: String
    let amount: Double
    let cardLast4: String
    let created: Date
    let status: String
}

struct FundsTransactionHistoryView: View {
    @State private var transactions: [Transaction] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading Transactions...")
            } else if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            } else if transactions.isEmpty {
                Text("No transactions available.")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List(transactions) { transaction in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amount: $\(String(format: "%.2f", transaction.amount))")
                            .font(.headline)
                        Text("Card Ending: **** \(transaction.cardLast4)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Date: \(formatDate(transaction.created))")
                            .font(.subheadline)
                        Text("Status: \(transaction.status.capitalized)")
                            .font(.subheadline)
                            .foregroundColor(transaction.status == "succeeded" ? .green : .red)
                    }
                    .padding(.vertical, 8)
                }
                .listStyle(PlainListStyle())
            }
        }
        .onAppear(perform: fetchStripeTransactions)
        .navigationTitle("Funds Transaction")
        .padding()
    }

    private func fetchStripeTransactions() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        // Replace with your logic to fetch the `stripeCustomerId` for the logged-in user
        let ref = Database.database().reference().child("users").child(userID)
        ref.child("stripeCustomerId").observeSingleEvent(of: .value) { snapshot in
            guard let customerId = snapshot.value as? String else {
                self.isLoading = false
                self.errorMessage = "Stripe customer ID not found."
                return
            }
            self.fetchStripePayments(customerId: customerId)
        }
    }

    private func fetchStripePayments(customerId: String) {
        let url = URL(string: "https://api.stripe.com/v1/charges?customer=\(customerId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer sk_test_51PlVh8P9Bz7XrwZPWSkDzX7AmaNgVr04yPOQWnbAECiYSWKtsmmVgD2Z8JYBY8a5dmEfKXaTewrBESb3fxIliwDo00HdJmKBKz", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Error fetching transactions: \(error.localizedDescription)"
                    return
                }

                guard let data = data,
                      let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                      let charges = response["data"] as? [[String: Any]] else {
                    self.errorMessage = "Error parsing transactions from Stripe."
                    return
                }

                self.transactions = charges.compactMap { charge in
                    guard let id = charge["id"] as? String,
                          let amount = charge["amount"] as? Double,
                          let createdTimestamp = charge["created"] as? TimeInterval,
                          let status = charge["status"] as? String,
                          let paymentMethodDetails = charge["payment_method_details"] as? [String: Any],
                          let card = paymentMethodDetails["card"] as? [String: Any],
                          let last4 = card["last4"] as? String else {
                        return nil
                    }

                    let createdDate = Date(timeIntervalSince1970: createdTimestamp)
                    return Transaction(id: id, amount: amount / 100.0, cardLast4: last4, created: createdDate, status: status)
                }
            }
        }.resume()
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
