//
//  HomeViewController.swift
//  Sentry
//
//  Created by Jonathan Vieri on 16/11/24.
//

import UIKit

class HomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    @IBAction func videoButtonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: "goToVideo", sender: self)
    }
    
}
