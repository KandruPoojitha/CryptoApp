
import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject private var vm: HomeViewModel
    @State private var showPortfolio: Bool = false
    @State private var selectedCoin: CoinModel? = nil
    @State private var showDetailView: Bool = false
    var body: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()
            VStack{
                HomeHeader
                SearchBarView(searchText: $vm.searchText)
                columnTitles
                coinsList
                Spacer(minLength: 0)
            }
        }
        .navigationBarBackButtonHidden(true)
        .background(
            NavigationLink(
                destination: DetailLoadingView(coin: $selectedCoin),
                           isActive: $showDetailView,
                           label: { EmptyView()})
        )
    }
}

struct HomeView_Previews: PreviewProvider{
    static var previews: some View{
        NavigationView{
            HomeView()
                .navigationBarHidden(true)
        }
        .environmentObject(dev.homeVM)
    
    }
}


extension HomeView {
    private var HomeHeader: some View {
        HStack{
            CirleButtonView(iconName: showPortfolio ? "plus" : "info")
                .animation(.none)
                .background(
                    CircleButtonAnimationView(animate: $showPortfolio))
            Spacer()
            Text(showPortfolio ? "Portfolio" : "Live Prices")
                .font(.headline)
                .fontWeight(.heavy)
                .foregroundColor(Color.theme.accent)
                .animation(.none)
            Spacer()
            CirleButtonView(iconName: "chevron.right")
                .rotationEffect(Angle(degrees: showPortfolio ? 180 : 0))
                .onTapGesture {
                    withAnimation(.spring()){
                        showPortfolio.toggle()
                    }
                }
        }
        .padding(.horizontal)
    }
    
    private var coinsList: some View {
        List {
            if !showPortfolio {
                ForEach(vm.allCoins) { coin in
                    CoinRowView(coin: coin, showHoldingCoins: false)
                        .listRowInsets(.init(top: 10, leading: 0, bottom: 10, trailing: 10))
                        .onTapGesture {
                            segue(coin: coin)
                        }
                }
            } else {
                ForEach(vm.portfolioCoins) { coin in
                    CoinRowView(coin: coin, showHoldingCoins: true)
                        .listRowInsets(.init(top: 10, leading: 0, bottom: 10, trailing: 10))
                        .onTapGesture {
                            segue(coin: coin)
                        }
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private func segue(coin: CoinModel){
        selectedCoin = coin
        showDetailView.toggle()
    }

    private var columnTitles: some View{
        HStack{
            Text("Coin")
            Spacer()
            if showPortfolio{
                Text("Holdings")
            }
            Text("Price")
                .frame(width: UIScreen.main.bounds.width / 3.5, alignment: .trailing)
        }
        .font(.caption)
        .foregroundColor(Color.theme.secondaryText)
        .padding(.horizontal)
    }
}
