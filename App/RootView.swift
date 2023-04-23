//
//  RootView.swift
//  StockPhoto
//
//  Created by Ben Lu on 12/10/22.
//

import App
import ComposableArchitecture
import ImageSegmentationClientImpl
import SwiftUI

struct RootView: View {
    let store = Store(
        initialState: StockPhoto.State(),
        reducer: StockPhoto()._printChanges()
    )
    var body: some View {
        NavigationStack {
            AppView(store: self.store)
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
