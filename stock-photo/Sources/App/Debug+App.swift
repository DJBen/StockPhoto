extension DebugState {
    static func project(_ appState: StockPhoto.State) -> DebugState {
        DebugState(
            model: appState.debugModel,
            accessToken: appState.login.accessToken
        )
    }

    func apply(_ appState: inout StockPhoto.State) {
        appState.debugModel = model
        appState.login.accessToken = accessToken
    }
}
