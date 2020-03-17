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


/// See this as a loginViewController.
class ViewController: UIViewController,MicrosoftLoginServiceDelegate,GoogleSiginServiceDelegate {
    
    
    
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
    
    private func launchDetailController() {
        //launch the detail
        guard let detailController = DetailPageViewController.instance() else {return}
        
        UIApplication.shared.windows.first?.rootViewController = detailController
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }
    
    //MARK:- Google
    func setUpGoogleSigin() {
        GoogleSiginService.shared.setUp(presentingViewController: self, delegate: self)
    }
    
    //MARK:- GoogleSiginServiceDelegate
    func didGoogleSignIn(user:GIDGoogleUser?, error:Error?) {
        if let error = error {
            
            if (error as NSError).code == GIDSignInErrorCode.hasNoAuthInKeychain.rawValue {
                print("The user has not signed in before or they have since signed out.")
            } else {
                print("\(error.localizedDescription)")
            }
            return
        }
        
        // Perform any operations on signed in user here.
        let userId = user?.userID                  // For client-side use only!
        let idToken = user?.authentication.idToken // Safe to send to the server
        let fullName = user?.profile.name
        let givenName = user?.profile.givenName
        //        let familyName = user.profile.familyName
        let email = user?.profile.email
        
        print("""
            User detail = \(userId),
            \(idToken),
            \(fullName),
            \(givenName),
            \(email)
            """)
        
        self.launchDetailController()
    }
    
    //MARK:- MICROSOFT
    var micrsoftService:MicrosoftLoginService?
    
    func setUpMicrsoftSigin() {
        micrsoftService = MicrosoftLoginService.shared
        micrsoftService?.setUp(withParentController:self,delegate:self)
    }
    
    @IBAction func MicrosoftLoginAction(_ sender: Any) {
        //setup signin mode info
        SignInMode.setPersistentSignMode(mode:.microsoft)
        self.micrsoftService?.callGraphAPI(sender as! UIButton)
    }
    
    //MARK:- MicrosoftLoginServiceDelegate
    func didAquireToken(token:String?, errror:MicroSoftLoginError?) {
        if let loginError = errror {
            //error found
            print("microsoft Error = \(loginError)")
        } else {
            //login successful
            print("token = \(token)")
            self.launchDetailController()
            
        }
    }
    
    func didGetUserDetail(user: Any?, error: MicroSoftLoginError?) {
        
    }
}

