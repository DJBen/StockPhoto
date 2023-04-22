import SwiftUI

class ZoomSwitcherViewModel: ObservableObject {
    @Published var selectedZoomLevel: ZoomLevel
    @Published var supportedZoomLevels: [ZoomLevel]
    
    init(
        selectedZoomLevel: ZoomLevel,
        supportedZoomLevels: [ZoomLevel]
    ) {
        self.selectedZoomLevel = selectedZoomLevel
        self.supportedZoomLevels = supportedZoomLevels
    }
}

struct ZoomLevel {
    let zoom: Int
    let label: String
}

struct ZoomSwitcherView: View {
    @ObservedObject var model: ZoomSwitcherViewModel
    
    let color = Color.black

    private func title(for zoomLevel: ZoomLevel, isSelected: Bool) -> String {
        isSelected ? "\(zoomLevel.label)x" : "\(zoomLevel.label)"
    }

    var body: some View {
        if model.supportedZoomLevels.isEmpty {
            EmptyView()
        } else {
            HStack(spacing: 16) {
                ForEach(model.supportedZoomLevels, id: \.zoom) { zoomLevel in
                    Button(action: {
                        withAnimation(.interactiveSpring()) {
                            model.selectedZoomLevel = zoomLevel
                        }
                    }) {
                        let scale = model.selectedZoomLevel.zoom == zoomLevel.zoom ? 1 : 0.75

                        Text(
                            title(for: zoomLevel, isSelected: model.selectedZoomLevel.zoom == zoomLevel.zoom)
                        )
                        .font(.system(size: model.selectedZoomLevel.zoom == zoomLevel.zoom ? 14 : 10, design: .rounded).bold())
                        .foregroundColor(
                            Color(uiColor: model.selectedZoomLevel.zoom == zoomLevel.zoom ? UIColor.systemYellow : UIColor.white)
                        )
                        .fixedSize()
                        .padding(.vertical, 10 * scale)
                        .padding(.horizontal, 10 * scale)
                        .background(color.opacity(0.5))
                        .cornerRadius(10)
                        .clipShape(Circle())
                    }
                    .foregroundColor(.white)
                    .buttonStyle(ZoomSwitcherButtonStyle())
                }
            }
            .padding(6)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
        }
    }
}

// Override the default button down state
struct ZoomSwitcherButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
    }
}

struct ZoomSwitcherView_Previews: PreviewProvider {
    struct ContentView: View {
        @StateObject private var model: ZoomSwitcherViewModel = .init(
            selectedZoomLevel: ZoomLevel(zoom: 1, label: "1"),
            supportedZoomLevels: [
                ZoomLevel(zoom: 1, label: "1"),
                ZoomLevel(zoom: 2, label: "2"),
                ZoomLevel(zoom: 3, label: "3")
            ]
        )
        var body: some View {
            VStack {
                ZoomSwitcherView(
                    model: model
                )
            }
        }
    }

    static var previews: some View {
        ContentView()
    }
}
