//
//  UploadViewController.swift
//  Sentry
//
//  Created by Jonathan Vieri on 26/11/24.
//

import UIKit
import AVKit
import PhotosUI

class UploadViewController: UIViewController {
    
    //MARK: - Private Properties
    @IBOutlet weak var uploadFromLibraryButton: UIButton!
    @IBOutlet weak var uploadFromURLButton: UIButton!
    
    private var okAction: UIAlertAction!
    private var videoSelection = [String: PHPickerResult]()
    
    //MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    //MARK: - Private Methods
    private func askForUserInput() {
        
        let alertController = UIAlertController(title: "Please enter video URL", message: "", preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Video URL"
            textField.addTarget(self, action: #selector(self.textfieldDidChange), for: .editingChanged)
        }
        
        okAction = UIAlertAction(title: "Ok", style: .default) { alertAction in
            
            if let text = alertController.textFields?.first?.text {
                print("Text input: \(text)")
                
                guard let videoURL = URL(string: text), UIApplication.shared.canOpenURL(videoURL) else {
                    self.presentSimpleAlert(title: "Invalid URL", message: "The provided URL is not valid")
                    return
                }
            
                Task {
                    await self.playVideo(from: videoURL)
                }
                
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        // Disable OK action at first
        okAction.isEnabled = false
        
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    @objc private func textfieldDidChange(_ field: UITextField) {
        guard let text = field.text else { return }
        okAction.isEnabled = !text.isEmpty
    }
    
    private func playVideo(from url: URL) async {
        // Check if the given URL is valid and load the metadata
        let asset = AVURLAsset(url: url)
        
        do {
            let isPlayable = try await asset.load(.isPlayable)
            
            if isPlayable {
                let player = AVPlayer(url: url)
                
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                
                present(playerViewController, animated: true) {
                    player.play()
                }
            } else {
                print("Video is not playable")
            }
            
        } catch {
            print("Error loading asset: \(error.localizedDescription)")
        }
    }
    
    private func presentSimpleAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(action)
        present(alertController, animated: true, completion: nil)
    }
    
    private func presentAlertWithActions(title: String, message: String, actions: [UIAlertAction]) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        for action in actions {
            alertController.addAction(action)
        }
        present(alertController, animated: true, completion: nil)
    }
    
    private func presentVideoPicker() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        
        // Set the filter to video only
        configuration.filter = .videos
        
        // Avoid transcoding if possible
        configuration.preferredAssetRepresentationMode = .current
        
        // Limit selection to only 1
        configuration.selectionLimit = 1
        
        // Show the picker
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func handleVideo(_ result: PHPickerResult) {
        // Check if the selected item conforms to the video type identifier
        // This is done to ensure that the item is a video file
        if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            
            // Load the file representation of the video from the item provider
            result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, error in
                
                do {
                    // Ensure the URL is valid and there's no error
                    guard let url = url, error == nil else {
                        print("Failed to get video URL")
                        return
                    }
                    
                    // Define a local URL in the temporary directory to store the video file
                    let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
                    
                    // Remove any existing file at local URL to avoid conflict
                    try? FileManager.default.removeItem(at: localURL)
                    
                    // Copy the video file from the provided URL to local URL
                    // This ensures the file is accessible for playback as PHPickerResult files are temporary
                    try FileManager.default.copyItem(at: url, to: localURL)
                    
                    // Switch to main thread to update the UI and play the video
                    DispatchQueue.main.async {
                        Task {
                            await self?.playVideo(from: localURL)
                        }
                    }
                } catch {
                    print("Error handling the video file: \(error)")
                }
            }
        }
    }
    
    //MARK: - IBActions
    @IBAction func uploadFromLibraryPressed(_ sender: UIButton) {
        print("Upload from library pressed")
        presentVideoPicker()
    }
    
    @IBAction func uploadFromURLPressed(_ sender: UIButton) {
        print("Upload from URL pressed")
        
        // Setup alert to prompt user for the URL and process the URL
        askForUserInput()
    }
}

//MARK: - PHPickerViewControllerDelegate
extension UploadViewController: PHPickerViewControllerDelegate {
    
    // Conformance to the PHPickerViewControllerDelegate to handle results of the media picker
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        // Dismiss the picker view, since the user has finished selecting a video
        dismiss(animated: true)
        print("User finish selecting video")
        
        // Ensure that the user has selected a video
        guard let result = results.first else { return }
        
        handleVideo(result)
    }
}
