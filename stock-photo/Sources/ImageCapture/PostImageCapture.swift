public struct PostImageCaptureState: Equatable {
    public var capturedImage: CapturedImage
    public var buttonText: PostImageCaptureButtonText

    public init(
        capturedImage: CapturedImage,
        buttonText: PostImageCaptureButtonText
    ) {
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
