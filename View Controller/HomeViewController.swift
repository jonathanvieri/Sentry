//
//  HomeViewController.swift
//  Sentry
//
//  Created by Jonathan Vieri on 16/11/24.
//

import UIKit

class HomeViewController: UIViewController {

    //MARK: - IBActions
    @IBAction func sourceButtonTapped(_ sender: UIButton) {
        let tag = sender.tag
        
        switch tag {
        case 1:
            print("Camera button tapped")
            performSegue(withIdentifier: "goToCamera", sender: self)
        case 2:
            print("File button tapped")
            performSegue(withIdentifier: "goToUpload", sender: self)
        default:
            print("Invalid tag provided")
        }
    }
    
    
    //MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
    
    }
    
}

