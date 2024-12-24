import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct DetailLoadingView: View {
    @Binding var coin: CoinModel?

    var body: some View {
        ZStack {
            if let coin = coin {
                DetailView(coin: coin) // Navigates to DetailView when coin is set
            } else {
                ProgressView() // Shows a loading spinner while data is being prepared
            }
        }
    }
}

struct DetailView: View {
    @StateObject private var vm: DetailViewModel
    @State private var showFullDescription: Bool = false
    @State private var isWishlisted: Bool = false
    @State private var showBuySheet: Bool = false // State for showing Buy sheet
    @State private var showSellSheet: Bool = false // State for showing Sell sheet

    private let columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    private let spacing: CGFloat = 30

    init(coin: CoinModel) {
        _vm = StateObject(wrappedValue: DetailViewModel(coin: coin))
    }

    var body: some View {
        ScrollView {
            VStack {
                ChartView(coin: vm.coin)
                    .padding(.vertical)

                VStack(spacing: 20) {
                    overviewTitle
                    Divider()
                    descriptionSection
                    overviewGrid
                    additionalTitle
                    Divider()
                    additionalGrid
                    websiteSection
                }
                .padding()

                // Buy and Sell Buttons
                HStack {
                    Button(action: {
                        showBuySheet.toggle()
                    }) {
                        Text("Buy")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    Button(action: {
                        showSellSheet.toggle()
                    }) {
                        Text("Sell")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
            }
        }
        .onAppear {
            checkIfWishlisted(coin: vm.coin)
        }
        .background(
            Color.theme.background
                .ignoresSafeArea()
        )
        .navigationTitle(vm.coin.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                navigationBarTrailingItems
            }
        }
        .sheet(isPresented: $showBuySheet) {
            BuySellView(coin: vm.coin, isBuying: true)
        }
        .sheet(isPresented: $showSellSheet) {
            BuySellView(coin: vm.coin, isBuying: false)
        }
    }
}

extension DetailView {
    private var navigationBarTrailingItems: some View {
        HStack(spacing: 8) {
            Text(vm.coin.symbol.uppercased())
                .font(.headline)
                .foregroundColor(Color.theme.secondaryText)
            Button(action: {
                toggleWishlist()
            }, label: {
                Image(systemName: isWishlisted ? "heart.fill" : "heart")
                    .foregroundColor(isWishlisted ? .red : .gray)
            })
        }
    }

    private var overviewTitle: some View {
        Text("Overview")
            .font(.title)
            .bold()
            .foregroundColor(Color.theme.accent)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var additionalTitle: some View {
        Text("Additional Details")
            .font(.title)
            .bold()
            .foregroundColor(Color.theme.accent)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var descriptionSection: some View {
        ZStack {
            if let coinDescription = vm.coinDescription, !coinDescription.isEmpty {
                VStack(alignment: .leading) {
                    Text(coinDescription)
                        .lineLimit(showFullDescription ? nil : 3)
                        .font(.callout)
                        .foregroundColor(Color.theme.secondaryText)

                    Button(action: {
                        withAnimation(.easeInOut) {
                            showFullDescription.toggle()
                        }
                    }, label: {
                        Text(showFullDescription ? "Less" : "Read more..")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.vertical, 4)
                    })
                    .accentColor(.blue)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var overviewGrid: some View {
        LazyVGrid(
            columns: columns,
            alignment: .leading,
            spacing: spacing,
            pinnedViews: [],
            content: {
                ForEach(vm.overviewStatistics) { stat in
                    StatisticView(stat: stat)
                }
            })
    }

    private var additionalGrid: some View {
        LazyVGrid(
            columns: columns,
            alignment: .leading,
            spacing: spacing,
            pinnedViews: [],
            content: {
                ForEach(vm.additionalStatistics) { stat in
                    StatisticView(stat: stat)
                }
            })
    }

    private var websiteSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let websiteString = vm.websiteURL, let url = URL(string: websiteString) {
                Link("Website", destination: url)
            }
            if let redditString = vm.redditURL, let url = URL(string: redditString) {
                Link("Reddit", destination: url)
            }
        }
        .accentColor(.blue)
        .frame(maxWidth: .infinity, alignment: .leading)
        .font(.headline)
    }

    // MARK: - Wishlist Logic

    private func checkIfWishlisted(coin: CoinModel) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("wishlist").child(userID)
        ref.observeSingleEvent(of: .value) { snapshot in
            if let coins = snapshot.value as? [String] {
                isWishlisted = coins.contains(coin.id)
            }
        }
    }

    private func toggleWishlist() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("wishlist").child(userID)

        ref.observeSingleEvent(of: .value) { snapshot in
            var coins = snapshot.value as? [String] ?? []
            if let index = coins.firstIndex(of: vm.coin.id) {
                // Remove from wishlist
                coins.remove(at: index)
                isWishlisted = false
            } else {
                // Add to wishlist
                coins.append(vm.coin.id)
                isWishlisted = true
            }
            ref.setValue(coins)
        }
    }
}
