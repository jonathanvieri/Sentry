//
//  UploadViewController.swift
//  Sentry
//
//  Created by Jonathan Vieri on 26/11/24.
//

import UIKit
import PhotosUI

class UploadViewController: UIViewController {

    //MARK: - Public Properties
    
    //MARK: - Private Properties
    @IBOutlet weak var uploadFromLibraryButton: UIButton!
    @IBOutlet weak var uploadFromURLButton: UIButton!
    
    
    //MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    //MARK: - Public Methods
    
    //MARK: - Private Methods
    private func askForUserInput() {
        
        let alertController = UIAlertController(title: "Please enter video URL", message: "", preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Video URL"
        }
        
        let okAction = UIAlertAction(title: "Ok", style: .default) { alertAction in
            print("Ok action pressed")
            
            if let text = alertController.textFields?.first?.text {
                print("Text inputted: \(text)")
                
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
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
    
    //MARK: - IBActions
    @IBAction func uploadFromLibraryPressed(_ sender: UIButton) {
        print("Upload from library pressed")
    }
    
    @IBAction func uploadFromURLPressed(_ sender: UIButton) {
        print("Upload from URL pressed")
        
        // Setup alert to prompt user for the URL and process the URL
        askForUserInput()
    }
}
