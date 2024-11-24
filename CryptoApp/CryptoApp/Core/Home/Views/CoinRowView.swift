import SwiftUI

struct CoinRowView: View {
    
    let coin: CoinModel
    let showHoldingCoins: Bool
    
    var body: some View {
        HStack(spacing: 0) {
        leftColumn
        Spacer()
        if showHoldingCoins {
            centerColumn
        }
        rightColumn
    }
        .font(.subheadline)
        .background(
            Color.theme.background.opacity(0.001)
        )
    }
}

struct CoinRowView_Previews: PreviewProvider{
    static var previews: some View {
        Group{
            CoinRowView(coin: DeveloperPreview.instance.coin, showHoldingCoins: true)
                .previewLayout(.sizeThatFits)
            CoinRowView(coin: DeveloperPreview.instance.coin, showHoldingCoins: true)
                .previewLayout(.sizeThatFits)
                .preferredColorScheme(.dark)
        }
    }
}

extension CoinRowView {
    private var leftColumn: some View {
        HStack(spacing: 0) {
            Text("\(coin.rank)")
                .font(.caption)
                .foregroundColor(Color.theme.secondaryText)
                .frame(minWidth: 30)
            AsyncImage(url: URL(string: coin.image)) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
            } placeholder: {
                ProgressView()
            }
            Spacer().frame(width: 8)
            VStack(alignment: .leading) {
                Text(coin.name)
                    .font(.headline)
                Text(coin.symbol.uppercased())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var centerColumn: some View {
        VStack(alignment: .trailing) {
            Text(coin.currentHoldingsValue.asCurrencyWith2Decimals())
                .bold()
            Text((coin.currentHoldings ?? 0).asNumberString())
        }
        .foregroundColor(Color.theme.accent)
    }
    
    private var rightColumn: some View {
        VStack(alignment: .trailing) {
            Text(coin.currentPrice.asCurrencyWith6Decimals())
                .bold()
                .foregroundColor(Color.theme.accent)
            Text((coin.priceChangePercentage24H ?? 0).asPercentString())
                .foregroundColor((coin.priceChangePercentage24H ?? 0) >= 0 ? .green : .red)
        }
        .frame(width: UIScreen.main.bounds.width / 3.5,alignment: .trailing)
    }
}
