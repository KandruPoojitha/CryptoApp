struct WishlistView: View {
    var body: some View {
        VStack {
            Text("Wishlist Page")
                .font(.largeTitle)
                .foregroundColor(Color.theme.accent)
        }
        .background(Color.theme.background.ignoresSafeArea())
    }
}
