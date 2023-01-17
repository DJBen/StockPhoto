/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's primary view controller that presents the camera interface.
*/

import UIKit
import AVFoundation
import DeviceExtension
import CoreLocation
import Photos

@preconcurrency class CameraViewController: UIViewController {

    private var spinner: UIActivityIndicatorView!

    var windowOrientation: UIInterfaceOrientation {
        return view.window?.windowScene?.interfaceOrientation ?? .unknown
    }

    let locationManager = CLLocationManager()

    // MARK: View Controller Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize UI

        previewView = PreviewView()
        previewView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewView)

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(focusAndExposeTap))
        previewView.addGestureRecognizer(tapGestureRecognizer)

        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(zoomFactorChanged))
        previewView.addGestureRecognizer(pinchGestureRecognizer)

        photoButton = UIButton(type: .custom)
        photoButton.setImage(UIImage(named: "CapturePhoto", in: .module, with: nil)!, for: .normal)
        photoButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        photoButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(photoButton)

        cameraButton = UIButton(type: .custom)
        cameraButton.setImage(UIImage(named: "FlipCamera", in: .module, with: nil)!, for: .normal)
        cameraButton.addTarget(self, action: #selector(changeCamera), for: .touchUpInside)
        cameraButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cameraButton)

        resumeButton = UIButton(type: .custom)
        resumeButton.setTitle("Tap to resume", for: .normal)
        resumeButton.setTitleColor(.systemYellow, for: .normal)
        resumeButton.addTarget(self, action: #selector(resumeInterruptedSession), for: .touchUpInside)
        resumeButton.isHidden = true
        resumeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(resumeButton)

        cameraUnavailableLabel = UILabel()
        cameraUnavailableLabel.textColor = .systemYellow
        cameraUnavailableLabel.text = "Camera Unavailable"
        cameraUnavailableLabel.font = .systemFont(ofSize: 25)
        cameraUnavailableLabel.isHidden = true
        cameraUnavailableLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cameraUnavailableLabel)

        capturingLivePhotoLabel = UILabel()
        capturingLivePhotoLabel.textColor = .systemYellow
        capturingLivePhotoLabel.text = "Live"
        capturingLivePhotoLabel.font = .systemFont(ofSize: 25)
        capturingLivePhotoLabel.isHidden = true
        capturingLivePhotoLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(capturingLivePhotoLabel)

        depthDataDeliveryButton = UIButton(type: .custom)
        depthDataDeliveryButton.setImage(UIImage(named: "DepthON", in: .module, with: nil)!, for: .normal)
        depthDataDeliveryButton.addTarget(self, action: #selector(toggleDepthDataDeliveryMode), for: .touchUpInside)
        depthDataDeliveryButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(depthDataDeliveryButton)

        HDRVideoModeButton = UIButton(type: .system)
        HDRVideoModeButton.setTitle("HDR On", for: .normal)
        HDRVideoModeButton.addTarget(self, action: #selector(toggleHDRVideoMode), for: .touchUpInside)
        HDRVideoModeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(HDRVideoModeButton)

        portraitEffectsMatteDeliveryButton = UIButton(type: .custom)
        portraitEffectsMatteDeliveryButton.setImage(UIImage(named: "PortraitMatteON", in: .module, with: nil)!, for: .normal)
        portraitEffectsMatteDeliveryButton.addTarget(self, action: #selector(togglePortraitEffectsMatteDeliveryMode), for: .touchUpInside)
        portraitEffectsMatteDeliveryButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(portraitEffectsMatteDeliveryButton)

        photoQualityPrioritizationSegControl = UISegmentedControl(
            items: [
                "Speed",
                "Balanced",
                "Quality"
            ]
        )
        photoQualityPrioritizationSegControl.selectedSegmentIndex = 1
        photoQualityPrioritizationSegControl.addTarget(self, action: #selector(togglePhotoQualityPrioritizationMode), for: .valueChanged)
        photoQualityPrioritizationSegControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(photoQualityPrioritizationSegControl)

        livePhotoModeButton = UIButton(type: .custom)
        livePhotoModeButton.setImage(UIImage(named: "LivePhotoON", in: .module, with: nil)!, for: .normal)
        livePhotoModeButton.addTarget(self, action: #selector(toggleLivePhotoMode), for: .touchUpInside)
        livePhotoModeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(livePhotoModeButton)

        // Set up constraints

        previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        previewView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        photoButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40).isActive = true
        photoButton.widthAnchor.constraint(equalTo: photoButton.heightAnchor).isActive = true
        photoButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        photoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        cameraButton.topAnchor.constraint(equalTo: photoButton.topAnchor).isActive = true
        cameraButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -30).isActive = true
        cameraButton.widthAnchor.constraint(equalTo: photoButton.widthAnchor).isActive = true
        cameraButton.heightAnchor.constraint(equalTo: photoButton.heightAnchor).isActive = true

        resumeButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        resumeButton.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true

        cameraUnavailableLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        cameraUnavailableLabel.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true

        livePhotoModeButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 30).isActive = true
        livePhotoModeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
        livePhotoModeButton.widthAnchor.constraint(equalTo: livePhotoModeButton.heightAnchor).isActive = true
        livePhotoModeButton.heightAnchor.constraint(equalToConstant: 50).isActive = true

        depthDataDeliveryButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor, constant: -50).isActive = true
        depthDataDeliveryButton.topAnchor.constraint(equalTo: livePhotoModeButton.topAnchor).isActive = true
        depthDataDeliveryButton.widthAnchor.constraint(equalTo: depthDataDeliveryButton.heightAnchor).isActive = true
        depthDataDeliveryButton.heightAnchor.constraint(equalTo: livePhotoModeButton.heightAnchor).isActive = true

        portraitEffectsMatteDeliveryButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor, constant: 50).isActive = true
        portraitEffectsMatteDeliveryButton.topAnchor.constraint(equalTo: livePhotoModeButton.topAnchor).isActive = true
        portraitEffectsMatteDeliveryButton.widthAnchor.constraint(equalTo: portraitEffectsMatteDeliveryButton.heightAnchor).isActive = true
        portraitEffectsMatteDeliveryButton.heightAnchor.constraint(equalTo: livePhotoModeButton.heightAnchor).isActive = true

        photoQualityPrioritizationSegControl.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        photoQualityPrioritizationSegControl.topAnchor.constraint(equalTo: livePhotoModeButton.bottomAnchor, constant: 15).isActive = true
        photoQualityPrioritizationSegControl.heightAnchor.constraint(equalToConstant: 25).isActive = true

        capturingLivePhotoLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        capturingLivePhotoLabel.topAnchor.constraint(equalTo: photoQualityPrioritizationSegControl.bottomAnchor, constant: 15).isActive = true

        HDRVideoModeButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
        HDRVideoModeButton.centerXAnchor.constraint(equalTo: previewView.centerXAnchor).isActive = true
        HDRVideoModeButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        HDRVideoModeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true

        // Disable the UI. Enable the UI later, if and only if the session starts running.
        cameraButton.isEnabled = false
        photoButton.isEnabled = false
        livePhotoModeButton.isEnabled = false
        depthDataDeliveryButton.isEnabled = false
        portraitEffectsMatteDeliveryButton.isEnabled = false
        photoQualityPrioritizationSegControl.isEnabled = false
        HDRVideoModeButton.isHidden = true
        cameraUnavailableLabel.isHighlighted = true

        // Set up the video preview view.
        previewView.session = session

        // Request location authorization so photos and videos can be tagged with their location.
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }

        /*
         Check the video authorization status. Video access is required and audio
         access is optional. If the user denies audio access, AVCam won't
         record audio during movie recording.
         */
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // The user has previously granted access to the camera.
            break

        case .notDetermined:
            /*
             The user has not yet been presented with the option to grant
             video access. Suspend the session queue to delay session
             setup until the access request has completed.

             Note that audio access will be implicitly requested when we
             create an AVCaptureDeviceInput for audio during session setup.
             */
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.sessionQueue.resume()
            })

        default:
            // The user has previously denied access.
            setupResult = .notAuthorized
        }

        /*
         Setup the capture session.
         In general, it's not safe to mutate an AVCaptureSession or any of its
         inputs, outputs, or connections from multiple threads at the same time.

         Don't perform these tasks on the main queue because
         AVCaptureSession.startRunning() is a blocking call, which can
         take a long time. Dispatch session setup to the sessionQueue, so
         that the main queue isn't blocked, which keeps the UI responsive.
         */
        sessionQueue.async {
            self.configureSession()
        }
        DispatchQueue.main.async {
            self.spinner = UIActivityIndicatorView(style: .large)
            self.spinner.color = UIColor.yellow
            self.previewView.addSubview(self.spinner)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        sessionQueue.async {
            switch self.setupResult {
            case .success:
                // Only setup observers and start the session if setup succeeded.
                self.addObservers()
                self.session.startRunning()
                self.isSessionRunning = self.session.isRunning

            case .notAuthorized:
                DispatchQueue.main.async {
                    let changePrivacySetting = "AVCam doesn't have permission to use the camera, please change privacy settings"
                    let message = NSLocalizedString(changePrivacySetting, comment: "Alert message when the user has denied access to the camera")
                    let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)

                    alertController.addAction(
                        UIAlertAction(
                            title: NSLocalizedString("OK", comment: "Alert OK button"),
                            style: .cancel,
                            handler: nil
                        )
                    )

                    alertController.addAction(
                        UIAlertAction(
                            title: NSLocalizedString("Settings", comment: "Alert button to open Settings"),
                            style: .`default`,
                            handler: { _ in
                                UIApplication.shared.open(
                                    URL(string: UIApplication.openSettingsURLString)!,
                                    options: [:],
                                    completionHandler: nil
                                )
                            }
                        )
                    )
                    self.present(alertController, animated: true, completion: nil)
                }

            case .configurationFailed:
                DispatchQueue.main.async {
                    let alertMsg = "Alert message when something goes wrong during capture session configuration"
                    let message = NSLocalizedString("Unable to capture media", comment: alertMsg)
                    let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)

                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                            style: .cancel,
                                                            handler: nil))

                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        sessionQueue.async {
            if self.setupResult == .success {
                self.session.stopRunning()
                self.isSessionRunning = self.session.isRunning
                self.removeObservers()
            }
        }

        super.viewWillDisappear(animated)
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        if let videoPreviewLayerConnection = previewView.videoPreviewLayer.connection {
            let deviceOrientation = UIDevice.current.orientation
            guard let newVideoOrientation = AVCaptureVideoOrientation(deviceOrientation: deviceOrientation),
                deviceOrientation.isPortrait || deviceOrientation.isLandscape else {
                    return
            }

            videoPreviewLayerConnection.videoOrientation = newVideoOrientation
        }
    }

    // MARK: Session Management

    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }

    private let session = AVCaptureSession()
    private var isSessionRunning = false
    private var selectedSemanticSegmentationMatteTypes = [AVSemanticSegmentationMatte.MatteType]()

    // Communicate with the session and other session objects on this queue.
    private let sessionQueue = DispatchQueue(label: "session queue")

    private var setupResult: SessionSetupResult = .success

    @objc dynamic var videoDeviceInput: AVCaptureDeviceInput!

    @objc private var previewView: PreviewView!

    // Call this on the session queue.
    /// - Tag: ConfigureSession
    private func configureSession() {
        if setupResult != .success {
            return
        }

        session.beginConfiguration()

        /*
         Do not create an AVCaptureMovieFileOutput when setting up the session because
         Live Photo is not supported when AVCaptureMovieFileOutput is added to the session.
         */
        session.sessionPreset = .photo

        // Add video input.
        do {
            var defaultVideoDevice: AVCaptureDevice?

            // Choose the back dual camera, if available, otherwise default to a wide angle camera.

            if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                defaultVideoDevice = dualCameraDevice
            } else if let dualWideCameraDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) {
                // If a rear dual camera is not available, default to the rear dual wide camera.
                defaultVideoDevice = dualWideCameraDevice
            } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                // If a rear dual wide camera is not available, default to the rear wide angle camera.
                defaultVideoDevice = backCameraDevice
            } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                // If the rear wide angle camera isn't available, default to the front wide angle camera.
                defaultVideoDevice = frontCameraDevice
            }
            guard let videoDevice = defaultVideoDevice else {
                print("Default video device is unavailable.")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }

            print("current: \(videoDevice.videoZoomFactor)")
            print("min: \(videoDevice.minAvailableVideoZoomFactor)")
            print("zooms: \(videoDevice.virtualDeviceSwitchOverVideoZoomFactors)")
            print("max: \(videoDevice.maxAvailableVideoZoomFactor)")

            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)

            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput

                setDefaultZoom(videoDevice: videoDevice)

                DispatchQueue.main.async {
                    /*
                     Dispatch video streaming to the main queue because AVCaptureVideoPreviewLayer is the backing layer for PreviewView.
                     You can manipulate UIView only on the main thread.
                     Note: As an exception to the above rule, it's not necessary to serialize video orientation changes
                     on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.

                     Use the window scene's orientation as the initial video orientation. Subsequent orientation changes are
                     handled by CameraViewController.viewWillTransition(to:with:).
                     */
                    var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
                    if self.windowOrientation != .unknown {
                        if let videoOrientation = AVCaptureVideoOrientation(interfaceOrientation: self.windowOrientation) {
                            initialVideoOrientation = videoOrientation
                        }
                    }

                    self.previewView.videoPreviewLayer.connection?.videoOrientation = initialVideoOrientation
                }
            } else {
                print("Couldn't add video device input to the session.")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
        } catch {
            print("Couldn't create video device input: \(error)")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }

        // Add an audio input device.
        do {
            let audioDevice = AVCaptureDevice.default(for: .audio)
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice!)

            if session.canAddInput(audioDeviceInput) {
                session.addInput(audioDeviceInput)
            } else {
                print("Could not add audio device input to the session")
            }
        } catch {
            print("Could not create audio device input: \(error)")
        }

        // Add the photo output.
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)

            photoOutput.isHighResolutionCaptureEnabled = true
            photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported
            photoOutput.isDepthDataDeliveryEnabled = photoOutput.isDepthDataDeliverySupported
            photoOutput.isPortraitEffectsMatteDeliveryEnabled = photoOutput.isPortraitEffectsMatteDeliverySupported
            photoOutput.enabledSemanticSegmentationMatteTypes = photoOutput.availableSemanticSegmentationMatteTypes
            selectedSemanticSegmentationMatteTypes = photoOutput.availableSemanticSegmentationMatteTypes
            photoOutput.maxPhotoQualityPrioritization = .quality
            livePhotoMode = photoOutput.isLivePhotoCaptureSupported ? .on : .off
            depthDataDeliveryMode = photoOutput.isDepthDataDeliverySupported ? .on : .off
            portraitEffectsMatteDeliveryMode = photoOutput.isPortraitEffectsMatteDeliverySupported ? .on : .off
            photoQualityPrioritizationMode = .balanced

        } else {
            print("Could not add photo output to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }

        session.commitConfiguration()
    }

    private func setDefaultZoom(videoDevice: AVCaptureDevice) {
        do {
            try videoDevice.lockForConfiguration()
            switch videoDevice.deviceType {
            case .builtInTripleCamera, .builtInDualWideCamera:
                videoDevice.videoZoomFactor = 2
                previousVideoZoomFactor = 2
            default:
                break
            }
            videoDevice.unlockForConfiguration()
        } catch {
            print("Could not lock device for configuration: \(error)")
        }
    }

    @objc private func resumeInterruptedSession(_ resumeButton: UIButton) {
        sessionQueue.async {
            /*
             The session might fail to start running, for example, if a phone or FaceTime call is still
             using audio or video. This failure is communicated by the session posting a
             runtime error notification. To avoid repeatedly failing to start the session,
             only try to restart the session in the error handler if you aren't
             trying to resume the session.
             */
            self.session.startRunning()
            self.isSessionRunning = self.session.isRunning
            if !self.session.isRunning {
                DispatchQueue.main.async {
                    let message = NSLocalizedString("Unable to resume", comment: "Alert message when unable to resume the session running")
                    let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil)
                    alertController.addAction(cancelAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            } else {
                DispatchQueue.main.async {
                    self.resumeButton.isHidden = true
                }
            }
        }
    }

    // MARK: Device Configuration

    private var cameraButton: UIButton!

    private var cameraUnavailableLabel: UILabel!

    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInDualCamera, .builtInDualWideCamera, .builtInWideAngleCamera],
        mediaType: .video,
        position: .unspecified
    )

    /// - Tag: ChangeCamera
    @objc private func changeCamera(_ cameraButton: UIButton) {
        cameraButton.isEnabled = false
        photoButton.isEnabled = false
        livePhotoModeButton.isEnabled = false
        depthDataDeliveryButton.isEnabled = false
        portraitEffectsMatteDeliveryButton.isEnabled = false
        photoQualityPrioritizationSegControl.isEnabled = false
        HDRVideoModeButton.isEnabled = false
        self.selectedMovieMode10BitDeviceFormat = nil

        sessionQueue.async {
            let currentVideoDevice = self.videoDeviceInput.device
            let currentPosition = currentVideoDevice.position

            let backVideoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInDualCamera, .builtInDualWideCamera, .builtInWideAngleCamera],
                mediaType: .video,
                position: .back
            )
            let frontVideoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInTrueDepthCamera, .builtInWideAngleCamera],
                mediaType: .video,
                position: .front
            )
            var newVideoDevice: AVCaptureDevice? = nil

            switch currentPosition {
            case .unspecified, .front:
                newVideoDevice = backVideoDeviceDiscoverySession.devices.first
            case .back:
                newVideoDevice = frontVideoDeviceDiscoverySession.devices.first
            @unknown default:
                print("Unknown capture position. Defaulting to back, dual-camera.")
                newVideoDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back)
            }

            if let videoDevice = newVideoDevice {
                do {
                    let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)

                    self.session.beginConfiguration()

                    // Remove the existing device input first, because AVCaptureSession doesn't support
                    // simultaneous use of the rear and front cameras.
                    self.session.removeInput(self.videoDeviceInput)

                    if self.session.canAddInput(videoDeviceInput) {
                        NotificationCenter.default.removeObserver(self, name: .AVCaptureDeviceSubjectAreaDidChange, object: currentVideoDevice)
                        NotificationCenter.default.addObserver(self, selector: #selector(self.subjectAreaDidChange), name: .AVCaptureDeviceSubjectAreaDidChange, object: videoDeviceInput.device)

                        self.session.addInput(videoDeviceInput)
                        self.videoDeviceInput = videoDeviceInput
                    } else {
                        self.session.addInput(self.videoDeviceInput)
                    }

                    self.setDefaultZoom(videoDevice: videoDevice)

                    /*
                     Set Live Photo capture and depth data delivery if it's supported. When changing cameras, the
                     `livePhotoCaptureEnabled` and `depthDataDeliveryEnabled` properties of the AVCapturePhotoOutput
                     get set to false when a video device is disconnected from the session. After the new video device is
                     added to the session, re-enable them on the AVCapturePhotoOutput, if supported.
                     */
                    self.photoOutput.isLivePhotoCaptureEnabled = self.photoOutput.isLivePhotoCaptureSupported
                    self.photoOutput.isDepthDataDeliveryEnabled = self.photoOutput.isDepthDataDeliverySupported
                    self.photoOutput.isPortraitEffectsMatteDeliveryEnabled = self.photoOutput.isPortraitEffectsMatteDeliverySupported
                    self.photoOutput.enabledSemanticSegmentationMatteTypes = self.photoOutput.availableSemanticSegmentationMatteTypes
                    self.selectedSemanticSegmentationMatteTypes = self.photoOutput.availableSemanticSegmentationMatteTypes
                    self.photoOutput.maxPhotoQualityPrioritization = .quality

                    self.session.commitConfiguration()
                } catch {
                    print("Error occurred while creating video device input: \(error)")
                }
            }

            DispatchQueue.main.async {
                self.cameraButton.isEnabled = true
                self.photoButton.isEnabled = true
                self.livePhotoModeButton.isEnabled = true
                self.depthDataDeliveryButton.isEnabled = self.photoOutput.isDepthDataDeliveryEnabled
                self.portraitEffectsMatteDeliveryButton.isEnabled = self.photoOutput.isPortraitEffectsMatteDeliveryEnabled
                self.photoQualityPrioritizationSegControl.isEnabled = true
            }
        }
    }

    @objc private func focusAndExposeTap(_ gestureRecognizer: UITapGestureRecognizer) {
        let devicePoint = previewView.videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: gestureRecognizer.location(in: gestureRecognizer.view))
        focus(with: .autoFocus, exposureMode: .autoExpose, at: devicePoint, monitorSubjectAreaChange: true)
    }

    private func focus(with focusMode: AVCaptureDevice.FocusMode,
                       exposureMode: AVCaptureDevice.ExposureMode,
                       at devicePoint: CGPoint,
                       monitorSubjectAreaChange: Bool) {

        sessionQueue.async {
            let device = self.videoDeviceInput.device
            do {
                try device.lockForConfiguration()

                /*
                 Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
                 Call set(Focus/Exposure)Mode() to apply the new point of interest.
                 */
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                    device.focusPointOfInterest = devicePoint
                    device.focusMode = focusMode
                }

                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
                    device.exposurePointOfInterest = devicePoint
                    device.exposureMode = exposureMode
                }

                device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                device.unlockForConfiguration()
            } catch {
                print("Could not lock device for configuration: \(error)")
            }
        }
    }

    private var previousVideoZoomFactor: CGFloat = 1

    @objc private func zoomFactorChanged(_ pinchGestureRecognizer: UIPinchGestureRecognizer) {
        sessionQueue.async {
            let currentDevice = self.videoDeviceInput.device

            switch pinchGestureRecognizer.state {
            case .began:
                try? currentDevice.lockForConfiguration()
                self.previousVideoZoomFactor = currentDevice.videoZoomFactor
            case .changed:
                let minZoomFactor = currentDevice.minAvailableVideoZoomFactor
                let maxZoomFactor = currentDevice.maxAvailableVideoZoomFactor
                currentDevice.videoZoomFactor = min(maxZoomFactor, max(minZoomFactor, self.previousVideoZoomFactor * pinchGestureRecognizer.scale))
            case .ended:
                currentDevice.unlockForConfiguration()
                self.previousVideoZoomFactor = currentDevice.videoZoomFactor
            default:
                break
            }
        }
    }

    // MARK: Capturing Photos

    private let photoOutput = AVCapturePhotoOutput()

    private var inProgressPhotoCaptureDelegates = [Int64: PhotoCaptureProcessor]()

    private var photoButton: UIButton!

    /// - Tag: CapturePhoto
    @objc private func capturePhoto(_ photoButton: UIButton) {
        /*
         Retrieve the video preview layer's video orientation on the main queue before
         entering the session queue. Do this to ensure that UI elements are accessed on
         the main thread and session configuration is done on the session queue.
         */
        let videoPreviewLayerOrientation = previewView.videoPreviewLayer.connection?.videoOrientation

        sessionQueue.async {
            if let photoOutputConnection = self.photoOutput.connection(with: .video) {
                photoOutputConnection.videoOrientation = videoPreviewLayerOrientation!
            }
            var photoSettings = AVCapturePhotoSettings()

            // Capture HEIF photos when supported. Enable auto-flash and high-resolution photos.
            if  self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            }

            if self.videoDeviceInput.device.isFlashAvailable {
                photoSettings.flashMode = .auto
            }

            photoSettings.isHighResolutionPhotoEnabled = true
            if let previewPhotoPixelFormatType = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
                photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPhotoPixelFormatType]
            }
            // Live Photo capture is not supported in movie mode.
            if self.livePhotoMode == .on && self.photoOutput.isLivePhotoCaptureSupported {
                let livePhotoMovieFileName = NSUUID().uuidString
                let livePhotoMovieFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((livePhotoMovieFileName as NSString).appendingPathExtension("mov")!)
                photoSettings.livePhotoMovieFileURL = URL(fileURLWithPath: livePhotoMovieFilePath)
            }

            photoSettings.isDepthDataDeliveryEnabled = (self.depthDataDeliveryMode == .on
                && self.photoOutput.isDepthDataDeliveryEnabled)

            photoSettings.isPortraitEffectsMatteDeliveryEnabled = (self.portraitEffectsMatteDeliveryMode == .on
                && self.photoOutput.isPortraitEffectsMatteDeliveryEnabled)

            if photoSettings.isDepthDataDeliveryEnabled {
                if !self.photoOutput.availableSemanticSegmentationMatteTypes.isEmpty {
                    photoSettings.enabledSemanticSegmentationMatteTypes = self.selectedSemanticSegmentationMatteTypes
                }
            }

            photoSettings.photoQualityPrioritization = self.photoQualityPrioritizationMode

            let photoCaptureProcessor = PhotoCaptureProcessor(with: photoSettings, willCapturePhotoAnimation: {
                // Flash the screen to signal that AVCam took a photo.
                DispatchQueue.main.async {
                    self.previewView.videoPreviewLayer.opacity = 0
                    UIView.animate(withDuration: 0.25) {
                        self.previewView.videoPreviewLayer.opacity = 1
                    }
                }
            }, livePhotoCaptureHandler: { capturing in
                self.sessionQueue.async {
                    if capturing {
                        self.inProgressLivePhotoCapturesCount += 1
                    } else {
                        self.inProgressLivePhotoCapturesCount -= 1
                    }

                    let inProgressLivePhotoCapturesCount = self.inProgressLivePhotoCapturesCount
                    DispatchQueue.main.async {
                        if inProgressLivePhotoCapturesCount > 0 {
                            self.capturingLivePhotoLabel.isHidden = false
                        } else if inProgressLivePhotoCapturesCount == 0 {
                            self.capturingLivePhotoLabel.isHidden = true
                        } else {
                            print("Error: In progress Live Photo capture count is less than 0.")
                        }
                    }
                }
            }, completionHandler: { photoCaptureProcessor in
                // When the capture is complete, remove a reference to the photo capture delegate so it can be deallocated.
                self.sessionQueue.async {
                    self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = nil
                }
            }, photoProcessingHandler: { animate in
                // Animates a spinner while photo is processing
                DispatchQueue.main.async {
                    if animate {
                        self.spinner.hidesWhenStopped = true
                        self.spinner.center = CGPoint(x: self.previewView.frame.size.width / 2.0, y: self.previewView.frame.size.height / 2.0)
                        self.spinner.startAnimating()
                    } else {
                        self.spinner.stopAnimating()
                    }
                }
            })

            // Specify the location the photo was taken
            photoCaptureProcessor.location = self.locationManager.location

            // The photo output holds a weak reference to the photo capture delegate and stores it in an array to maintain a strong reference.
            self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = photoCaptureProcessor
            self.photoOutput.capturePhoto(with: photoSettings, delegate: photoCaptureProcessor)
        }
    }

    private enum LivePhotoMode {
        case on
        case off
    }

    private enum DepthDataDeliveryMode {
        case on
        case off
    }

    private enum PortraitEffectsMatteDeliveryMode {
        case on
        case off
    }

    private var livePhotoMode: LivePhotoMode = .off

    private var livePhotoModeButton: UIButton!

    @objc private func toggleLivePhotoMode(_ livePhotoModeButton: UIButton) {
        sessionQueue.async {
            self.livePhotoMode = (self.livePhotoMode == .on) ? .off : .on
            let livePhotoMode = self.livePhotoMode

            DispatchQueue.main.async {
                if livePhotoMode == .on {
                    self.livePhotoModeButton.setImage(UIImage(named: "LivePhotoON", in: .module, with: nil), for: [])
                } else {
                    self.livePhotoModeButton.setImage(UIImage(named: "LivePhotoOFF", in: .module, with: nil), for: [])
                }
            }
        }
    }

    private var depthDataDeliveryMode: DepthDataDeliveryMode = .off

    private var depthDataDeliveryButton: UIButton!

    @objc func toggleDepthDataDeliveryMode(_ depthDataDeliveryButton: UIButton) {
        sessionQueue.async {
            self.depthDataDeliveryMode = (self.depthDataDeliveryMode == .on) ? .off : .on
            let depthDataDeliveryMode = self.depthDataDeliveryMode
            if depthDataDeliveryMode == .on {
                self.portraitEffectsMatteDeliveryMode = .on
            } else {
                self.portraitEffectsMatteDeliveryMode = .off
            }

            DispatchQueue.main.async {
                if depthDataDeliveryMode == .on {
                    self.depthDataDeliveryButton.setImage(UIImage(named: "DepthON", in: .module, with: nil), for: [])
                    self.portraitEffectsMatteDeliveryButton.setImage(UIImage(named: "PortraitMatteON", in: .module, with: nil), for: [])
                } else {
                    self.depthDataDeliveryButton.setImage(UIImage(named: "DepthOFF", in: .module, with: nil), for: [])
                    self.portraitEffectsMatteDeliveryButton.setImage(UIImage(named: "PortraitMatteOFF", in: .module, with: nil), for: [])
                }
            }
        }
    }

    private var portraitEffectsMatteDeliveryMode: PortraitEffectsMatteDeliveryMode = .off

    private var portraitEffectsMatteDeliveryButton: UIButton!

    @objc func togglePortraitEffectsMatteDeliveryMode(_ portraitEffectsMatteDeliveryButton: UIButton) {
        sessionQueue.async {
            if self.portraitEffectsMatteDeliveryMode == .on {
                self.portraitEffectsMatteDeliveryMode = .off
            } else {
                self.portraitEffectsMatteDeliveryMode = (self.depthDataDeliveryMode == .off) ? .off : .on
            }
            let portraitEffectsMatteDeliveryMode = self.portraitEffectsMatteDeliveryMode

            DispatchQueue.main.async {
                if portraitEffectsMatteDeliveryMode == .on {
                    self.portraitEffectsMatteDeliveryButton.setImage(UIImage(named: "PortraitMatteON", in: .module, with: nil), for: [])
                } else {
                    self.portraitEffectsMatteDeliveryButton.setImage(UIImage(named: "PortraitMatteOFF", in: .module, with: nil), for: [])
                }
            }
        }
    }

    private var photoQualityPrioritizationMode: AVCapturePhotoOutput.QualityPrioritization = .balanced

    private var photoQualityPrioritizationSegControl: UISegmentedControl!

    @objc func togglePhotoQualityPrioritizationMode(_ photoQualityPrioritizationSegControl: UISegmentedControl) {
        let selectedQuality = photoQualityPrioritizationSegControl.selectedSegmentIndex
        sessionQueue.async {
            switch selectedQuality {
            case 0 :
                self.photoQualityPrioritizationMode = .speed
            case 1 :
                self.photoQualityPrioritizationMode = .balanced
            case 2 :
                self.photoQualityPrioritizationMode = .quality
            default:
                break
            }
        }
    }

    func tenBitVariantOfFormat(activeFormat: AVCaptureDevice.Format) -> AVCaptureDevice.Format? {
        let formats = self.videoDeviceInput.device.formats
        let formatIndex = formats.firstIndex(of: activeFormat)!

        let activeDimensions = CMVideoFormatDescriptionGetDimensions(activeFormat.formatDescription)
        let activeMaxFrameRate = activeFormat.videoSupportedFrameRateRanges.last?.maxFrameRate
        let activePixelFormat = CMFormatDescriptionGetMediaSubType(activeFormat.formatDescription)

        /*
         AVCaptureDeviceFormats are sorted from smallest to largest in resolution and frame rate.
         For each resolution and max frame rate there's a cluster of formats that only differ in pixelFormatType.
         Here, we're looking for an 'x420' variant of the current activeFormat.
        */
        if activePixelFormat != kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange {
            // Current activeFormat is not a 10-bit HDR format, find its 10-bit HDR variant.
            for index in formatIndex + 1..<formats.count {
                let format = formats[index]
                let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                let maxFrameRate = format.videoSupportedFrameRateRanges.last?.maxFrameRate
                let pixelFormat = CMFormatDescriptionGetMediaSubType(format.formatDescription)

                // Don't advance beyond the current format cluster
                if activeMaxFrameRate != maxFrameRate || activeDimensions.width != dimensions.width || activeDimensions.height != dimensions.height {
                    break
                }

                if pixelFormat == kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange {
                    return format
                }
            }
        } else {
            return activeFormat
        }

        return nil
    }

    private var selectedMovieMode10BitDeviceFormat: AVCaptureDevice.Format?

    private enum HDRVideoMode {
        case on
        case off
    }

    private var HDRVideoMode: HDRVideoMode = .on

    private var HDRVideoModeButton: UIButton!

    @objc private func toggleHDRVideoMode(_ HDRVideoModeButton: UIButton) {
        sessionQueue.async {
            self.HDRVideoMode = (self.HDRVideoMode == .on) ? .off : .on
            let HDRVideoMode = self.HDRVideoMode

            DispatchQueue.main.async {
                if HDRVideoMode == .on {
                    do {
                        try self.videoDeviceInput.device.lockForConfiguration()
                        self.videoDeviceInput.device.activeFormat = self.selectedMovieMode10BitDeviceFormat!
                        self.videoDeviceInput.device.unlockForConfiguration()
                    } catch {
                        print("Could not lock device for configuration: \(error)")
                    }
                    self.HDRVideoModeButton.setTitle("HDR On", for: .normal)
                } else {
                    self.session.beginConfiguration()
                    self.session.sessionPreset = .high
                    self.session.commitConfiguration()
                    self.HDRVideoModeButton.setTitle("HDR Off", for: .normal)
                }
            }
        }
    }

    private var inProgressLivePhotoCapturesCount = 0

    private var capturingLivePhotoLabel: UILabel!

    private var resumeButton: UIButton!

    // MARK: KVO and Notifications

    private var keyValueObservations = [NSKeyValueObservation]()
    /// - Tag: ObserveInterruption
    private func addObservers() {
        let keyValueObservation = session.observe(\.isRunning, options: .new) { _, change in
            guard let isSessionRunning = change.newValue else { return }
            let isLivePhotoCaptureEnabled = self.photoOutput.isLivePhotoCaptureEnabled
            let isDepthDeliveryDataEnabled = self.photoOutput.isDepthDataDeliveryEnabled
            let isPortraitEffectsMatteEnabled = self.photoOutput.isPortraitEffectsMatteDeliveryEnabled

            DispatchQueue.main.async {
                // Only enable the ability to change camera if the device has more than one camera.
                self.cameraButton.isEnabled = isSessionRunning && self.videoDeviceDiscoverySession.uniqueDevicePositionsCount > 1
                self.photoButton.isEnabled = isSessionRunning
                self.livePhotoModeButton.isEnabled = isSessionRunning && isLivePhotoCaptureEnabled
                self.depthDataDeliveryButton.isEnabled = isSessionRunning && isDepthDeliveryDataEnabled
                self.portraitEffectsMatteDeliveryButton.isEnabled = isSessionRunning && isPortraitEffectsMatteEnabled
                self.photoQualityPrioritizationSegControl.isEnabled = isSessionRunning
            }
        }
        keyValueObservations.append(keyValueObservation)

        let systemPressureStateObservation = observe(\.videoDeviceInput.device.systemPressureState, options: .new) { _, change in
            guard let systemPressureState = change.newValue else { return }
            self.setRecommendedFrameRateRangeForPressureState(systemPressureState: systemPressureState)
        }
        keyValueObservations.append(systemPressureStateObservation)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(subjectAreaDidChange),
                                               name: .AVCaptureDeviceSubjectAreaDidChange,
                                               object: videoDeviceInput.device)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionRuntimeError),
                                               name: .AVCaptureSessionRuntimeError,
                                               object: session)

        /*
         A session can only run when the app is full screen. It will be interrupted
         in a multi-app layout, introduced in iOS 9, see also the documentation of
         AVCaptureSessionInterruptionReason. Add observers to handle these session
         interruptions and show a preview is paused message. See the documentation
         of AVCaptureSessionWasInterruptedNotification for other interruption reasons.
         */
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionWasInterrupted),
                                               name: .AVCaptureSessionWasInterrupted,
                                               object: session)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionInterruptionEnded),
                                               name: .AVCaptureSessionInterruptionEnded,
                                               object: session)
    }

    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)

        for keyValueObservation in keyValueObservations {
            keyValueObservation.invalidate()
        }
        keyValueObservations.removeAll()
    }

    @objc
    func subjectAreaDidChange(notification: NSNotification) {
        let devicePoint = CGPoint(x: 0.5, y: 0.5)
        focus(with: .continuousAutoFocus, exposureMode: .continuousAutoExposure, at: devicePoint, monitorSubjectAreaChange: false)
    }

    /// - Tag: HandleRuntimeError
    @objc
    func sessionRuntimeError(notification: NSNotification) {
        guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else { return }

        print("Capture session runtime error: \(error)")
        // If media services were reset, and the last start succeeded, restart the session.
        if error.code == .mediaServicesWereReset {
            sessionQueue.async {
                if self.isSessionRunning {
                    self.session.startRunning()
                    self.isSessionRunning = self.session.isRunning
                } else {
                    DispatchQueue.main.async {
                        self.resumeButton.isHidden = false
                    }
                }
            }
        } else {
            resumeButton.isHidden = false
        }
    }

    /// - Tag: HandleSystemPressure
    private func setRecommendedFrameRateRangeForPressureState(systemPressureState: AVCaptureDevice.SystemPressureState) {
        /*
         The frame rates used here are only for demonstration purposes.
         Your frame rate throttling may be different depending on your app's camera configuration.
         */
        let pressureLevel = systemPressureState.level
        if pressureLevel == .serious || pressureLevel == .critical {
            do {
                try self.videoDeviceInput.device.lockForConfiguration()
                print("WARNING: Reached elevated system pressure level: \(pressureLevel). Throttling frame rate.")
                self.videoDeviceInput.device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 20)
                self.videoDeviceInput.device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 15)
                self.videoDeviceInput.device.unlockForConfiguration()
            } catch {
                print("Could not lock device for configuration: \(error)")
            }
        } else if pressureLevel == .shutdown {
            print("Session stopped running due to shutdown system pressure level.")
        }
    }

    /// - Tag: HandleInterruption
    @objc
    func sessionWasInterrupted(notification: NSNotification) {
        /*
         In some scenarios you want to enable the user to resume the session.
         For example, if music playback is initiated from Control Center while
         using AVCam, then the user can let AVCam resume
         the session running, which will stop music playback. Note that stopping
         music playback in Control Center will not automatically resume the session.
         Also note that it's not always possible to resume, see `resumeInterruptedSession(_:)`.
         */
        if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?,
            let reasonIntegerValue = userInfoValue.integerValue,
            let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) {
            print("Capture session was interrupted with reason \(reason)")

            var showResumeButton = false
            if reason == .audioDeviceInUseByAnotherClient || reason == .videoDeviceInUseByAnotherClient {
                showResumeButton = true
            } else if reason == .videoDeviceNotAvailableWithMultipleForegroundApps {
                // Fade-in a label to inform the user that the camera is unavailable.
                cameraUnavailableLabel.alpha = 0
                cameraUnavailableLabel.isHidden = false
                UIView.animate(withDuration: 0.25) {
                    self.cameraUnavailableLabel.alpha = 1
                }
            } else if reason == .videoDeviceNotAvailableDueToSystemPressure {
                print("Session stopped running due to shutdown system pressure level.")
            }
            if showResumeButton {
                // Fade-in a button to enable the user to try to resume the session running.
                resumeButton.alpha = 0
                resumeButton.isHidden = false
                UIView.animate(withDuration: 0.25) {
                    self.resumeButton.alpha = 1
                }
            }
        }
    }

    @objc
    func sessionInterruptionEnded(notification: NSNotification) {
        print("Capture session interruption ended")

        if !resumeButton.isHidden {
            UIView.animate(withDuration: 0.25,
                           animations: {
                            self.resumeButton.alpha = 0
            }, completion: { _ in
                self.resumeButton.isHidden = true
            })
        }
        if !cameraUnavailableLabel.isHidden {
            UIView.animate(withDuration: 0.25,
                           animations: {
                            self.cameraUnavailableLabel.alpha = 0
            }, completion: { _ in
                self.cameraUnavailableLabel.isHidden = true
            }
            )
        }
    }
}

extension AVCaptureVideoOrientation {
    init?(deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeRight
        case .landscapeRight: self = .landscapeLeft
        default: return nil
        }
    }

    init?(interfaceOrientation: UIInterfaceOrientation) {
        switch interfaceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeLeft
        case .landscapeRight: self = .landscapeRight
        default: return nil
        }
    }
}

extension AVCaptureDevice.DiscoverySession {
    var uniqueDevicePositionsCount: Int {

        var uniqueDevicePositions = [AVCaptureDevice.Position]()

        for device in devices where !uniqueDevicePositions.contains(device.position) {
            uniqueDevicePositions.append(device.position)
        }

        return uniqueDevicePositions.count
    }
}
