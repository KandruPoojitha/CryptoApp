//
//  HomeView.swift
//  CrtptoApp
//
//  Created by Lithin Varma on 2024-10-07.
//

import SwiftUI

struct CirleButtonView: View {
    let iconName: String
    var body: some View {
        Image(systemName: iconName)
            .font(.headline)
            .foregroundColor(Color.theme.accent)
            .frame(width: 50,height: 50)
            .background(
                Circle()
                    .foregroundColor(Color.theme.background)
            )
            .shadow(
                color: Color.theme.background.opacity(0.25),
                radius: 10,x: 0,y: 0)
            .padding()
    }
}

struct CirleButtonView_Previews: PreviewProvider{
    static var previews: some View{
        Group{
            CirleButtonView(iconName: "info")
                .previewLayout(.sizeThatFits)
            CirleButtonView(iconName: "plus")
                .previewLayout(.sizeThatFits)
                .colorScheme(.dark)
        }
        
    }
}
