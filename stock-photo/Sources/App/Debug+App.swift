extension DebugState {
    static func project(_ appState: StockPhoto.State) -> DebugState {
        DebugState(
            model: appState.debugModel,
            account: appState.login.account
        )
    }

    func apply(_ appState: inout StockPhoto.State) {
        appState.debugModel = model
        appState.login.account = account
    }
}
