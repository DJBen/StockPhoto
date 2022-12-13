//
//  RootView.swift
//  StockPhoto
//
//  Created by Ben Lu on 12/10/22.
//

import AppCore
import ComposableArchitecture
import SwiftUI

struct RootView: View {
    let store = Store(
        initialState: StockPhoto.State(),
        reducer: StockPhoto()._printChanges()
    )
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }
        .padding()
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
