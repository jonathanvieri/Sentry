//
//  CameraViewController.swift
//  Sentry
//
//  Created by Jonathan Vieri on 17/11/24.
//

import UIKit
import AVFoundation
import Vision

class CameraViewController: UIViewController {

    //MARK: - Public Properties
    
    
    //MARK: - Private Properties
    private var captureSession: AVCaptureSession!
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    
    //MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCamera()
        
        // Start the capture session
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }
    
    deinit {
        captureSession.stopRunning()
    }
    
    //MARK: - Public Methods
  
    //MARK: - Private Methods
    private func setupCamera() {
        
        // Create the capture session and start configuring AVCapture Session
        captureSession = AVCaptureSession()
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high
        
        // Commit the configuration, whether it succeed or there is an error
        defer {
            captureSession.commitConfiguration()
        }
        
        // Try to get the capture device, starting from back camera and then moving on to front camera
        let videoDevice: AVCaptureDevice?
        
        if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            videoDevice = backCameraDevice
        } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            videoDevice = frontCameraDevice
        } else {
            print("No camera device found")
            return
        }
        
        // Add the input to the session
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice!),
            captureSession.canAddInput(videoDeviceInput)
        else { return }
        
        captureSession.addInput(videoDeviceInput)
        
        // Add video output to the session
        let videoOutput = AVCaptureVideoDataOutput()
        
        // Drop frames if processing cannot keep up
        videoOutput.alwaysDiscardsLateVideoFrames = true
        
        // Set the video settings to match format for Vision
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        // Set delegate from Sample Buffer Delegate protocol to process each frame for detecting motion
        let videoqueue = DispatchQueue(label: "videoQueue")
        videoOutput.setSampleBufferDelegate(self, queue: videoqueue)
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        } else {
            fatalError("Unable to add output to session")
        }
        
        // Add video preview layer
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer)
    }
   
}

//MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
    }
}
