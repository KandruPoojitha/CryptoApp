import SwiftUI
import FirebaseAuth
import FirebaseDatabase
import Stripe

struct ManageCardsView: View {
    var stripeCustomerId: String // Stripe Customer ID passed from AccountView

    @State private var cards: [STPPaymentMethod] = []
    @State private var isLoading: Bool = true
    @State private var showAddCardView: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading cards...")
            } else if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
            } else if cards.isEmpty {
                VStack(spacing: 20) {
                    Text("No cards available.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Button("Add Card") {
                        showAddCardView = true
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
            } else {
                List(cards, id: \.stripeId) { card in
                    HStack {
                        Text("\(card.card?.brand.description ?? "Card") Ending in \(card.card?.last4 ?? "****")")
                        Spacer()
                        if let expMonth = card.card?.expMonth, let expYear = card.card?.expYear {
                            Text("\(expMonth)/\(expYear)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Unknown Expiry")
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }

            Spacer()

            Button(action: {
                showAddCardView = true
            }) {
                Text("Add Card")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
            }
            .padding()
        }
        .onAppear {
            fetchCards()
        }
        .sheet(isPresented: $showAddCardView) {
            AddCardView(stripeCustomerId: stripeCustomerId) {
                fetchCards()
            }
        }
        .navigationTitle("Manage Cards")
        .padding()
    }

    private func fetchCards() {
        guard !stripeCustomerId.isEmpty else {
            self.errorMessage = "Stripe Customer ID is empty."
            self.isLoading = false
            return
        }

        isLoading = true
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
                   let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let paymentMethods = response["data"] as? [[String: Any]] {
                    self.cards = paymentMethods.compactMap { STPPaymentMethod.decodedObject(fromAPIResponse: $0) }
                } else {
                    self.errorMessage = "Error parsing card data from Stripe."
                }
            }
        }.resume()
    }
}
