//
//  RootView.swift
//  StockPhoto
//
//  Created by Ben Lu on 12/10/22.
//

import App
import ComposableArchitecture
import SwiftUI

struct RootView: View {
    let store: StoreOf<StockPhoto>

    var body: some View {
        NavigationStack {
            AppView(store: self.store)
        }
    }
}
