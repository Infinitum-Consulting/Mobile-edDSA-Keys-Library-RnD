//
//  QrCodeScanner.swift
//  testing-ios-app-1
//
//  Created by Yash Goyal on 02/11/24.
//

import SwiftUI
import AVFoundation

struct QrCodeScannerView: UIViewControllerRepresentable {
    var onScan: (String) -> Void
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<QrCodeScannerView>) -> UIViewController {
        // Create a QR code scanner
        let scannerViewController = QRScannerController()
        scannerViewController.delegate = makeCoordinator()
        return scannerViewController
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onScan)
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<QrCodeScannerView>) {
        // Update the view controller
    }
}

class QRScannerController: UIViewController {
    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?

    var delegate: AVCaptureMetadataOutputObjectsDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Get the back-facing camera for capturing videos
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Failed to get the camera device")
            return
        }

        let videoInput: AVCaptureDeviceInput

        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            videoInput = try AVCaptureDeviceInput(device: captureDevice)

        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            print(error)
            return
        }

        // Set the input device on the capture session.
        captureSession.addInput(videoInput)

        // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
        let captureMetadataOutput = AVCaptureMetadataOutput()
        captureSession.addOutput(captureMetadataOutput)

        // Set delegate and use the default dispatch queue to execute the call back
        captureMetadataOutput.setMetadataObjectsDelegate(delegate, queue: DispatchQueue.main)
        captureMetadataOutput.metadataObjectTypes = [ .qr ]

        // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer!)

        // Start video capture.
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }

    }

}

class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    var onScan: (String) -> Void
    var lastScanTime: TimeInterval

    init(_ onScan: @escaping (String) -> Void) {
        self.onScan = onScan
        self.lastScanTime = 0.0
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        let currentTime = NSDate().timeIntervalSince1970
        if currentTime - lastScanTime < 0.5 {
            return
        }
        lastScanTime = currentTime
        
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects.count == 0 {
//            scanResult = "No QR code detected"
            return
        }

        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject

        if metadataObj.type == AVMetadataObject.ObjectType.qr,
           let result = metadataObj.stringValue {
            onScan(result)
        }
    }
}

// #Preview {
//     QrCodeScannerView()
// }
