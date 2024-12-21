struct PortfolioView: View {
    var body: some View {
        VStack {
            Text("Portfolio Page")
                .font(.largeTitle)
                .foregroundColor(Color.theme.accent)
        }
        .background(Color.theme.background.ignoresSafeArea())
    }
}
