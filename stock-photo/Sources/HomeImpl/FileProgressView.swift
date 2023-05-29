import SwiftUI

struct FileProgressView: View {
    let totalBytesSent: Int64
    let totalBytesExpectedToSend: Int64

    let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    private var percentage: Float {
        if totalBytesExpectedToSend == 0 {
            return 0
        } else {
            return Float(totalBytesSent) / Float(totalBytesExpectedToSend)
        }
    }

    var body: some View {
        let percentageString = numberFormatter.string(from: NSNumber(value: percentage)) ?? "0%"

        ProgressView(
            value: percentage
        ) {
            Text(
                "Uploading image...",
                comment: "Title of download progress view"
            )
        } currentValueLabel: {
            Text(percentageString)
        }
        .animation(.default, value: percentage)
    }
}

struct FileProgressView_Previews: PreviewProvider {
    static var previews: some View {
        FileProgressView(
            totalBytesSent: 30,
            totalBytesExpectedToSend: 100
        )

        FileProgressView(
            totalBytesSent: 0,
            totalBytesExpectedToSend: 0
        )
    }
}
