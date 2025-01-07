struct AccountView: View {
    var body: some View {
        VStack {
            Text("Account Page")
                .font(.largeTitle)
                .foregroundColor(Color.theme.accent)
        }
        .background(Color.theme.background.ignoresSafeArea())
    }
}
