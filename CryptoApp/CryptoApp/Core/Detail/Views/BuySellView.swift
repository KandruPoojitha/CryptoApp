import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct BuySellView: View {
    let coin: CoinModel
    let isBuying: Bool // `true` for buying, `false` for selling

    @State private var enteredAmount: String = ""
    @State private var calculatedQuantity: String = "0.0"
    @State private var walletBalance: Double = 0.0
    @State private var errorMessage: String?
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 20) {
            Text(isBuying ? "Buy \(coin.name)" : "Sell \(coin.name)")
                .font(.title)
                .bold()
                .padding(.top)

            Text("Current \(isBuying ? "Buying" : "Selling") Price")
                .font(.headline)
                .foregroundColor(.secondary)

            Text(String(format: "$%.2f", coin.currentPrice))
                .font(.largeTitle)
                .bold()
                .foregroundColor(.green)

            Divider()

            VStack(alignment: .leading, spacing: 15) {
                Text("How much do you want to \(isBuying ? "buy" : "sell")?")
                    .font(.headline)

                HStack {
                    VStack(alignment: .leading) {
                        TextField("In USD", text: $enteredAmount)
                            .keyboardType(.decimalPad)
                            .onChange(of: enteredAmount, perform: { _ in
                                calculateQuantity()
                            })
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)

                        Text("In \(coin.symbol.uppercased()): \(calculatedQuantity)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }

                Text("USD Balance: \(String(format: "$%.2f", walletBalance))")
                    .font(.subheadline)
                    .foregroundColor(.primary)

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()

            Button(action: {
                isBuying ? handleBuy() : handleSell()
            }) {
                Text(isBuying ? "Buy \(coin.name)" : "Sell \(coin.name)")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isBuying ? Color.green : Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .onAppear(perform: fetchWalletBalance)
    }

    // MARK: - Fetch Wallet Balance
    private func fetchWalletBalance() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("users").child(userID).child("balance")

        ref.observeSingleEvent(of: .value) { snapshot in
            self.walletBalance = snapshot.value as? Double ?? 0.0
        }
    }

    // MARK: - Calculate Quantity
    private func calculateQuantity() {
        guard let amount = Double(enteredAmount), amount > 0 else {
            calculatedQuantity = "0.0"
            return
        }

        calculatedQuantity = String(format: "%.6f", amount / coin.currentPrice)
    }

    // MARK: - Handle Buy
    private func handleBuy() {
        guard let amount = Double(enteredAmount), amount > 0 else {
            errorMessage = "Please enter a valid amount."
            return
        }

        let quantity = amount / coin.currentPrice

        guard walletBalance >= amount else {
            errorMessage = "Insufficient funds. You need $\(String(format: "%.2f", amount - walletBalance)) more."
            return
        }

        updateWalletBalanceAndPortfolio(amount: amount, quantity: quantity, isBuying: true)
    }

    // MARK: - Handle Sell
    private func handleSell() {
        guard let amount = Double(enteredAmount), amount > 0 else {
            errorMessage = "Please enter a valid amount."
            return
        }

        let quantity = amount / coin.currentPrice

        fetchPortfolioQuantity { portfolioQuantity in
            if quantity > portfolioQuantity {
                errorMessage = "You cannot sell more than \(String(format: "%.6f", portfolioQuantity)) coins."
                return
            }

            self.updateWalletBalanceAndPortfolio(amount: amount, quantity: quantity, isBuying: false)
        }
    }

    // MARK: - Update Wallet and Portfolio
    private func updateWalletBalanceAndPortfolio(amount: Double, quantity: Double, isBuying: Bool) {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        let userRef = Database.database().reference().child("users").child(userID)
        let portfolioRef = Database.database().reference().child("portfolio").child(userID).child(coin.id)

        // Update Wallet Balance
        userRef.child("balance").observeSingleEvent(of: .value) { snapshot in
            let currentBalance = snapshot.value as? Double ?? 0.0
            let updatedBalance = isBuying ? (currentBalance - amount) : (currentBalance + amount)

            userRef.child("balance").setValue(updatedBalance)

            // Update Portfolio
            portfolioRef.observeSingleEvent(of: .value) { snapshot in
                var currentQuantity = snapshot.childSnapshot(forPath: "quantity").value as? Double ?? 0.0
                var investedAmount = snapshot.childSnapshot(forPath: "investedAmount").value as? Double ?? 0.0

                if isBuying {
                    // Buying a coin
                    currentQuantity += quantity
                    investedAmount += amount
                } else {
                    // Selling a coin
                    currentQuantity -= quantity
                    investedAmount -= amount

                    // If the user sells all holdings, remove the coin from the portfolio
                    if currentQuantity <= 0 {
                        portfolioRef.removeValue()
                        self.saveTransaction(amount: amount, quantity: quantity, isBuying: isBuying)
                        self.presentationMode.wrappedValue.dismiss()
                        return
                    }
                }

                // Update or set the portfolio values
                portfolioRef.setValue([
                    "name": coin.name,
                    "symbol": coin.symbol,
                    "image": coin.image,
                    "currentPrice": coin.currentPrice,
                    "quantity": currentQuantity,
                    "investedAmount": investedAmount
                ])

                self.saveTransaction(amount: amount, quantity: quantity, isBuying: isBuying)
                self.presentationMode.wrappedValue.dismiss()
            }
        }
    }

    // MARK: - Fetch Portfolio Quantity
    private func fetchPortfolioQuantity(completion: @escaping (Double) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        let portfolioRef = Database.database().reference().child("portfolio").child(userID).child(coin.id)
        portfolioRef.observeSingleEvent(of: .value) { snapshot in
            let currentQuantity = snapshot.childSnapshot(forPath: "quantity").value as? Double ?? 0.0
            completion(currentQuantity)
        }
    }

    // MARK: - Save Transaction
    private func saveTransaction(amount: Double, quantity: Double, isBuying: Bool) {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        let transactionRef = Database.database().reference().child("transactions").child(userID).childByAutoId()
        let transactionData: [String: Any] = [
            "coinName": coin.name,
            "coinSymbol": coin.symbol,
            "quantity": quantity,
            "amount": amount,
            "type": isBuying ? "buy" : "sell",
            "timestamp": ServerValue.timestamp()
        ]

        transactionRef.setValue(transactionData)
    }
}
