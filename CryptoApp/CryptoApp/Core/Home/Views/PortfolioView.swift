import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct PortfolioView: View {
    @EnvironmentObject private var vm: HomeViewModel
    @State private var portfolioCoins: [CoinModel] = []
    @State private var searchText: String = ""
    @State private var selectedCoin: CoinModel? = nil
    @State private var showDetailView: Bool = false

    var body: some View {
        NavigationView {
            VStack {
                portfolioSummarySection
                    .padding(.horizontal)
                    .padding(.top, 10)

                SearchBarView(searchText: $searchText)
                    .padding(.horizontal)
                    .padding(.top, 10)

                columnTitles
                    .padding(.top, 5)

                if filteredCoins.isEmpty {
                    Spacer()
                    VStack {
                        Image(systemName: "magnifyingglass.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(Color.theme.secondaryText)
                        Text("Your portfolio is empty or no coins match your search.")
                            .font(.headline)
                            .foregroundColor(Color.theme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(filteredCoins) { coin in
                            CoinRowView(coin: coin, showHoldingCoins: true)
                                .listRowInsets(.init(top: 10, leading: 0, bottom: 10, trailing: 10))
                                .onTapGesture {
                                    segue(coin: coin)
                                }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .background(
                NavigationLink(
                    destination: DetailLoadingView(coin: $selectedCoin),
                    isActive: $showDetailView,
                    label: { EmptyView() }
                )
            )
            .onAppear {
                fetchPortfolio()
            }
            .navigationTitle("Portfolio")
            .background(Color.theme.background.ignoresSafeArea())
        }
    }

    private var filteredCoins: [CoinModel] {
        if searchText.isEmpty {
            return portfolioCoins
        } else {
            return portfolioCoins.filter {
                $0.name.lowercased().contains(searchText.lowercased()) ||
                $0.symbol.lowercased().contains(searchText.lowercased())
            }
        }
    }

    private var columnTitles: some View {
        HStack {
            Text("Coin")
            Spacer()
            Text("Holdings")
            Text("Value")
                .frame(width: UIScreen.main.bounds.width / 3.5, alignment: .trailing)
        }
        .font(.caption)
        .foregroundColor(Color.theme.secondaryText)
        .padding(.horizontal)
    }

    private var portfolioSummarySection: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading) {
                    Text("CURRENT")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("$\(totalPortfolioValue, specifier: "%.2f")")
                        .font(.title2)
                        .bold()
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("INVESTED")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("$\(totalInvestedValue, specifier: "%.2f")")
                        .font(.title2)
                        .bold()
                }
            }
            Divider()
            HStack {
                VStack(alignment: .leading) {
                    Text("RETURNS")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("$\(returnsValue, specifier: "%.2f")")
                        .font(.title2)
                        .bold()
                        .foregroundColor(returnsValue >= 0 ? .green : .red)
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("RETURNS %")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(returnsPercentage, specifier: "%.2f")%")
                        .font(.title2)
                        .bold()
                        .foregroundColor(returnsPercentage >= 0 ? .green : .red)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.1))
                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
        )
        .padding(.horizontal)
    }

    private var totalPortfolioValue: Double {
        portfolioCoins.reduce(0) { $0 + ($1.currentHoldingsValue) }
    }

    private var totalInvestedValue: Double {
        portfolioCoins.reduce(0) { $0 + ($1.currentHoldings ?? 0) * ($1.currentPrice / ((100 + ($1.priceChangePercentage24H ?? 0)) / 100)) }
    }

    private var returnsValue: Double {
        totalPortfolioValue - totalInvestedValue
    }

    private var returnsPercentage: Double {
        totalInvestedValue > 0 ? (returnsValue / totalInvestedValue) * 100 : 0
    }

    private func fetchPortfolio() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("portfolio").child(userID)

        ref.getData { error, snapshot in
            if let error = error {
                print("Error fetching portfolio data: \(error.localizedDescription)")
                return
            }

            if let coinIDs = snapshot?.value as? [String: [String: Any]] {
                let portfolioCoins = vm.allCoins.filter { coin in
                    coinIDs.keys.contains(coin.id)
                }.map { coin -> CoinModel in
                    var updatedCoin = coin
                    if let details = coinIDs[coin.id],
                       let quantity = details["quantity"] as? Double {
                        updatedCoin.currentHoldings = quantity
                    }
                    return updatedCoin
                }

                DispatchQueue.main.async {
                    self.portfolioCoins = portfolioCoins
                }
            } else {
                DispatchQueue.main.async {
                    self.portfolioCoins = []
                }
            }
        }
    }

    private func segue(coin: CoinModel) {
        selectedCoin = coin
        showDetailView.toggle()
    }
}
