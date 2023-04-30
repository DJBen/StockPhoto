public struct PostImageCaptureState: Equatable {
    public var accessToken: String?
    public var capturedImage: CapturedImage
    public var buttonText: PostImageCaptureButtonText

    public init(
        accessToken: String? = nil,
        capturedImage: CapturedImage,
        buttonText: PostImageCaptureButtonText
    ) {
        self.accessToken = accessToken
        self.capturedImage = capturedImage
        self.buttonText = buttonText
    }
}

public enum PostImageCaptureAction: Equatable {
    case retakeImage
    case uploadImage
}

public enum PostImageCaptureButtonText {
    case retake
    case chooseAnother
}
