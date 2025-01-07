struct BuySellView: View {
    let coin: CoinModel
    let isBuying: Bool

    @State private var amount: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text(isBuying ? "Buy \(coin.name)" : "Sell \(coin.name)")
                .font(.title)
                .fontWeight(.bold)
            TextField("Amount", text: $amount)
                .keyboardType(.decimalPad)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)

            Button(action: {
                handleTransaction()
            }) {
                Text(isBuying ? "Confirm Buy" : "Confirm Sell")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isBuying ? Color.green : Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Spacer()
        }
        .padding()
    }

    private func handleTransaction() {
        // Add logic to handle buy/sell actions here
        print("\(isBuying ? "Buying" : "Selling") \(amount) of \(coin.name)")
    }
}
