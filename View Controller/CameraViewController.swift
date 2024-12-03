//
//  CameraViewController.swift
//  Sentry
//
//  Created by Jonathan Vieri on 17/11/24.
//

import UIKit
import AVFoundation
import Vision
import CoreML

class CameraViewController: UIViewController {
    
    //MARK: - Private Properties
    private var captureSession: AVCaptureSession!
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    private var visionModel: VNCoreMLModel!
    private var requests = [VNRequest]()
    private var detectionOverlay: CALayer! = nil
    private var bufferSize: CGSize = .zero
    
    //MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup Live Capture
        setupCamera()
        
        // Setup the layers
        setupLayers()
        
        // Setup Vision
        setupVision()
        
        // Start the capture session
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }
    
    deinit {
        captureSession.stopRunning()
    }
  
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
        
        // Add a video output to the session
        let videoDataOutput = AVCaptureVideoDataOutput()

        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
            
            // Drop frames if processing cannot keep up
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            
            // Set the video settings to match format for Vision
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            
            // Set delegate from Sample Buffer Delegate protocol to process each frame for detecting motion
            let videoqueue = DispatchQueue(label: "videoQueue")
            videoDataOutput.setSampleBufferDelegate(self, queue: videoqueue)
        } else {
            fatalError("Unable to add output to session")
        }
        
        // Update the buffer size
        let captureConnection = videoDataOutput.connection(with: .video)
        captureConnection?.isEnabled = true
        
        do {
            try videoDevice?.lockForConfiguration()
            if let formatDescription = videoDevice?.activeFormat.formatDescription {
                let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
                bufferSize.width = CGFloat(dimensions.width)
                bufferSize.height = CGFloat(dimensions.height)
            }
            videoDevice?.unlockForConfiguration()
        } catch {
            print("Error updating buffer size: \(error)")
        }
        
        // Add video preview layer
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer)
    }
    
    private func setupLayers() {
        detectionOverlay = CALayer()
        detectionOverlay.bounds = CGRect(
            x: 0.0,
            y: 0.0,
            width: bufferSize.width,
            height: bufferSize.height)
        detectionOverlay.position = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        view.layer.addSublayer(detectionOverlay)
    }
    
    private func setupVision() {
        
        // Load the YOLO model
        guard let modelURL = Bundle.main.url(forResource: "YOLOv3Tiny", withExtension: "mlmodelc") else {
            print("Model file is missing")
            return
        }
        print("Model file found: \(modelURL)")
        
        do {
            let configuration = MLModelConfiguration()
            let model = try YOLOv3Tiny(configuration: configuration)
            visionModel = try VNCoreMLModel(for: model.model)
            
            let objectRecognition = VNCoreMLRequest(model: visionModel) { (request, error) in
                // Early exit if there are errors
                if let error = error {
                    print("Error during Vision request: \(error)")
                    return
                }
                
                DispatchQueue.main.async {
                    if let results = request.results {
                        self.handleDetection(results)
                    }
                }
            }
            
            // Store the requests
            self.requests = [objectRecognition]
        } catch {
            print("Model loading went wrong: \(error)")
        }
    }
   
    private func handleDetection(_ results: [Any]) {
        
        // Begin a new CATransaction for smooth updates and disables animations
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        // Clear previous detection overlays
        detectionOverlay.sublayers = nil
        
        // Iterate through the detection results
        for observation in results where observation is VNRecognizedObjectObservation {
            
            // Safely cast to VNRecognizedObjectObservation
            guard let objectObservation = observation as? VNRecognizedObjectObservation else { continue }
            
            // Get only the label with highest level of confidence
            guard let topLabelObservation = objectObservation.labels.first else {
                print("No labels found for the object")
                return
            }
            
            // Convert normalized bounding box to image coordinates
            let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(bufferSize.width), Int(bufferSize.height))
            
            // Create a bounding box layer
            let shapeLayer = self.createBoundingBoxLayer(with: objectBounds)
            
            // Add a text layer to the bounding box layer
            let textLayer = self.createTextLayer(with: objectBounds, identifier: topLabelObservation.identifier, confidence: topLabelObservation.confidence)
            
            // Add the text layer to the bounding box layer and add bounding box layer to detection overlay
            shapeLayer.addSublayer(textLayer)
            detectionOverlay.addSublayer(shapeLayer)
        }
        
        // Commit the CATransaction
        CATransaction.commit()
    }
    
    private func createBoundingBoxLayer(with bounds: CGRect) -> CALayer {
        let shapeLayer = CALayer()
        
        // Set the layer's bound and position
        shapeLayer.bounds = bounds
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        
        // Set the shape layer name
        shapeLayer.name = "Found Objects Bounding Box"
        
        // Style the bounding box
        shapeLayer.backgroundColor = UIColor.red.cgColor
        shapeLayer.cornerRadius = 12
        shapeLayer.opacity = 0.3
        
        return shapeLayer
    }
    
    private func createTextLayer(with bounds: CGRect, identifier: String, confidence: VNConfidence) -> CATextLayer {
        let textLayer = CATextLayer()
        
        // Set the text layer name
        textLayer.name = "Found Objects Label"
        
        // Set the text content
        let formattedConfidence = "Confidence: \(Int(confidence * 100))%"
        textLayer.string = "\(identifier)\n\(formattedConfidence)"
        
        // Style the text
        textLayer.fontSize = 24
        textLayer.foregroundColor = UIColor.white.cgColor
        textLayer.backgroundColor = UIColor.black.withAlphaComponent(0.5).cgColor
        textLayer.alignmentMode = .center
        
        // Ensure the zPosition to ensure the text is on top
        textLayer.zPosition = 1
        
        // Ensure rendering is crisp
        textLayer.contentsScale = 2.0
        
        // Position the text layer to be above the bounding box
        let textHeight: CGFloat = 60
        textLayer.frame = CGRect(
            x: bounds.origin.x,
            y: bounds.origin.y - textHeight,
            width: bounds.width,
            height: textHeight)
        
        return textLayer
    }
}

//MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        // Convert video frame into format that Vision can process
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Failed to convert video frame into CVImageBuffer")
            return
        }
        
        // Create a Vision image request handler for the pixel buffer
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print("Failed to perform Vision request: \(error)")
        }
    }
}
