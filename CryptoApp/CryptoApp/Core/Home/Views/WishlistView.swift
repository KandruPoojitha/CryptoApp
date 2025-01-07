import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct WishlistView: View {
    @EnvironmentObject private var vm: HomeViewModel
    @State private var wishlistCoins: [CoinModel] = []
    @State private var searchText: String = "" // Search bar text
    @State private var selectedCoin: CoinModel? = nil // For navigation
    @State private var showDetailView: Bool = false // Controls navigation to DetailView

    var body: some View {
        NavigationView {
            VStack {
                SearchBarView(searchText: $searchText) // Search bar
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
                        Text("Your wishlist is empty or no coins match your search.")
                            .font(.headline)
                            .foregroundColor(Color.theme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(filteredCoins) { coin in
                            CoinRowView(coin: coin, showHoldingCoins: false)
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
                fetchWishlist()
            }
            .navigationTitle("Wishlist")
            .background(Color.theme.background.ignoresSafeArea())
        }
    }

    private var filteredCoins: [CoinModel] {
        if searchText.isEmpty {
            return wishlistCoins
        } else {
            return wishlistCoins.filter {
                $0.name.lowercased().contains(searchText.lowercased()) ||
                $0.symbol.lowercased().contains(searchText.lowercased())
            }
        }
    }

    private var columnTitles: some View {
        HStack {
            Text("Coin")
            Spacer()
            Text("Price")
                .frame(width: UIScreen.main.bounds.width / 3.5, alignment: .trailing)
        }
        .font(.caption)
        .foregroundColor(Color.theme.secondaryText)
        .padding(.horizontal)
    }

    private func fetchWishlist() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("wishlist").child(userID)
        
        ref.getData { error, snapshot in
            if let error = error {
                print("Error fetching wishlist data: \(error.localizedDescription)")
                return
            }

            if let coinIDs = snapshot?.value as? [String] {
                // Filter the coins using the IDs stored in the user's wishlist
                wishlistCoins = vm.allCoins.filter { coinIDs.contains($0.id) }
            } else {
                wishlistCoins = []
            }
        }
    }

    private func segue(coin: CoinModel) {
        selectedCoin = coin
        showDetailView.toggle()
    }
}

