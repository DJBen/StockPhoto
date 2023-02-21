import SwiftUI

class ZoomSwitcherViewModel: ObservableObject  {
    @Published var selectedZoomLevel: ZoomSwitcherView.ZoomLevel
    
    init(selectedZoomLevel: ZoomSwitcherView.ZoomLevel) {
        self.selectedZoomLevel = selectedZoomLevel
    }
}

struct ZoomSwitcherView: View {
    public enum ZoomLevel: Int, CaseIterable {
        case base = 0
        case double
        case triple
    }

    @ObservedObject var model: ZoomSwitcherViewModel
    
    let color = Color.black

    private func title(for zoomLevel: ZoomLevel, isSelected: Bool) -> String {
        switch zoomLevel {
        case .base:
            return isSelected ? "1x" : "1"
        case .double:
            return isSelected ? "2x" : "2"
        case .triple:
            return isSelected ? "3x" : "3"
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            ForEach(ZoomLevel.allCases, id: \.rawValue) { zoomLevel in
                Button(action: {
                    withAnimation(.interactiveSpring()) {
                        model.selectedZoomLevel = zoomLevel
                    }
                }) {
                    let scale = model.selectedZoomLevel == zoomLevel ? 1 : 0.75

                    Text(
                        title(for: zoomLevel, isSelected: model.selectedZoomLevel == zoomLevel)
                    )
                    .font(.system(size: model.selectedZoomLevel == zoomLevel ? 14 : 10, design: .rounded).bold())
                    .foregroundColor(Color(uiColor: model.selectedZoomLevel == zoomLevel ? UIColor.systemYellow : UIColor.white))
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

// Override the default button down state
struct ZoomSwitcherButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
    }
}

struct ZoomSwitcherView_Previews: PreviewProvider {
    struct ContentView: View {
        @StateObject private var model: ZoomSwitcherViewModel = .init(selectedZoomLevel: .base)
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
