
import SwiftUI
import FirebaseDatabase
import FirebaseAuth

struct TransactionHistoryView: View {
    @State private var transactions: [TransactionModel] = []

    var body: some View {
        VStack {
            if transactions.isEmpty {
                Text("No transactions found.")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List(transactions) { transaction in
                    VStack(alignment: .leading, spacing: 5) {
                        Text("\(transaction.type.capitalized) \(transaction.coinName)")
                            .font(.headline)

                        HStack {
                            Text("Amount: $\(String(format: "%.2f", transaction.amount))")
                            Spacer()
                            Text("Quantity: \(String(format: "%.6f", transaction.quantity)) \(transaction.coinSymbol.uppercased())")
                        }
                        .font(.subheadline)

                        Text("Date: \(transaction.formattedDate)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("Transaction History")
        .onAppear(perform: fetchTransactions)
    }

    // MARK: - Fetch Transactions
    private func fetchTransactions() {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        let ref = Database.database().reference().child("transactions").child(userID)
        ref.observe(.value) { snapshot in
            var fetchedTransactions: [TransactionModel] = []

            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let dict = childSnapshot.value as? [String: Any],
                   let coinName = dict["coinName"] as? String,
                   let coinSymbol = dict["coinSymbol"] as? String,
                   let quantity = dict["quantity"] as? Double,
                   let amount = dict["amount"] as? Double,
                   let type = dict["type"] as? String,
                   let timestamp = dict["timestamp"] as? TimeInterval {

                    let transaction = TransactionModel(
                        id: childSnapshot.key,
                        coinName: coinName,
                        coinSymbol: coinSymbol,
                        quantity: quantity,
                        amount: amount,
                        type: type,
                        timestamp: timestamp
                    )
                    fetchedTransactions.append(transaction)
                }
            }

            // Sort transactions by timestamp (most recent first)
            self.transactions = fetchedTransactions.sorted { $0.timestamp > $1.timestamp }
        }
    }
}

// MARK: - Transaction Model
struct TransactionModel: Identifiable {
    let id: String
    let coinName: String
    let coinSymbol: String
    let quantity: Double
    let amount: Double
    let type: String // "buy" or "sell"
    let timestamp: TimeInterval

    // Convert timestamp to a readable date
    var formattedDate: String {
        let date = Date(timeIntervalSince1970: timestamp / 1000)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}


