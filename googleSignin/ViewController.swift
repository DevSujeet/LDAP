//
//  ViewController.swift
//  googleSignin
//
//  Created by Sujeet.Kumar on 27/02/20.
//  Copyright © 2020 Cuddle. All rights reserved.
//

import UIKit
import GoogleSignIn

class ViewController: UIViewController {
    
    @IBOutlet weak var signInButton: GIDSignInButton! {
        didSet {
//            signInButton.set
        }
    }

//    @IBAction func didTapSignOut(_ sender: AnyObject) {
//      GIDSignIn.sharedInstance().signOut()
//    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        GIDSignIn.sharedInstance()?.presentingViewController = self
        
        // Automatically sign in the user.
        GIDSignIn.sharedInstance()?.restorePreviousSignIn()
    }

    
    static func instance() -> ViewController? {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let detailController = mainStoryboard.instantiateViewController(withIdentifier: "ViewController") as? ViewController else {return nil}
        return detailController
    }

}

