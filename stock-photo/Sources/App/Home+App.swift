import Home

extension HomeState {
    static func project(_ appState: StockPhoto.State) -> HomeState {
        HomeState(
            account: appState.login.account,
            model: appState.homeModel,
            segmentationModel: appState.segmentationModel,
            selectedProjectID: {
                for destination in appState.destinations {
                    switch destination {
                    case .selectedProject(let projectID):
                        return projectID
                    default:
                        break
                    }
                }
                return nil
            }()
        )
    }

    func apply(_ appState: inout StockPhoto.State) {
        appState.homeModel = model
        appState.segmentationModel = segmentationModel
    }
}
