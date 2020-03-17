//
//  ViewController.swift
//  googleSignin
//
//  Created by Sujeet.Kumar on 27/02/20.
//  Copyright © 2020 Cuddle. All rights reserved.
//

import UIKit
import GoogleSignIn
import MSAL

class ViewController: UIViewController,MicrosoftLoginServiceDelegate {
    
    @IBOutlet weak var signInButton: GIDSignInButton! {
        didSet {
//            signInButton.set
        }
    }

    @IBOutlet weak var microsoftLoginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        setUpGoogleSigin()
        
        setUpMicrsoftSigin()
    }

    
    static func instance() -> ViewController? {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let detailController = mainStoryboard.instantiateViewController(withIdentifier: "ViewController") as? ViewController else {return nil}
        return detailController
    }
    //MARK:- Google
    func setUpGoogleSigin() {
        GIDSignIn.sharedInstance()?.presentingViewController = self
               
               // Automatically sign in the user.
        GIDSignIn.sharedInstance()?.restorePreviousSignIn()
    }
    
    //MARK:- MICROSOFT
    var micrsoftService:MicrosoftLoginService?
    func setUpMicrsoftSigin() {
        micrsoftService = MicrosoftLoginService(withParentController:self,delegate:self)
    }
    
    @IBAction func MicrosoftLoginAction(_ sender: Any) {
        self.micrsoftService?.callGraphAPI(sender as! UIButton)
    }
    
    //MARK:- MicrosoftLoginServiceDelegate
    func didAquireToken(token:String, errror:Error?) {
        if let loginError = errror {
            //error found
            print("microsoft Error = \(loginError)")
        } else {
            //login successful
            print("token = \(token)")
            
        }
    }
}

