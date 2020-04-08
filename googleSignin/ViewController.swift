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
class ViewController: UIViewController,MicrosoftLoginServiceDelegate,GoogleSiginServiceDelegate,PingFederateSigninProtocol {
    
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
        
        
        setUpPingFederateSignIn()
    }

    
    static func instance() -> ViewController? {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let detailController = mainStoryboard.instantiateViewController(withIdentifier: "ViewController") as? ViewController else {return nil}
        return detailController
    }
    
    private func launchDetailController() {
        //launch the detail
        AppDelegate.getAppDelegate().launchDetailController()
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
        //
        //setup signin mode info
        SignInMode.setPersistentSignMode(mode:.google)
        // Perform any operations on signed in user here.
        let userId = user?.userID                  // For client-side use only!
        let idToken = user?.authentication.idToken // Safe to send to the server
        let fullName = user?.profile.name
        let givenName = user?.profile.givenName
        //        let familyName = user.profile.familyName
        let email = user?.profile.email
        
        print("""
            Google User detail = \(userId),
            \(idToken),
            \(fullName),
            \(givenName),
            \(email)
            """)
        
        self.launchDetailController()
    }
    
    //MARK::- PingFederate
    var pingFederateService:PingFederateLoginService?
    
    
    @IBAction func pingFederateLoginAction(_ sender: Any) {
        self.pingFederateService?.actionSignIn()
    }
    
    func setUpPingFederateSignIn() {
        pingFederateService = PingFederateLoginService.shared
        pingFederateService?.setUp(withConfig: PingFederateConfig(),
                                   presentingController: self,
                                   delegate: self)
    }
    
    func didSignin(withToken token: String?, error: PingFederateLoginError?) {
        
    }
    
    func didGetUserDetail(user: Any?, error: PingFederateLoginError?) {
        guard let userDetail = user else {
            print("Got error \(error)")
            return
        }
        
        guard let userInfo = userDetail as? [String:Any] else {return}
        
        print("UserInfo Email = \(userInfo["email"])")
        //setup signin mode info
        SignInMode.setPersistentSignMode(mode:.pingFederate)
        let token = pingFederateService?.accessToken ?? ""
        print("token = \(String(describing: token))")
        self.launchDetailController()
    }
    
    
    //MARK:- MICROSOFT
    var micrsoftService:MicrosoftLoginService?
    
    func setUpMicrsoftSigin() {
        micrsoftService = MicrosoftLoginService.shared
        micrsoftService?.setUp(withParentController:self,delegate:self)
    }
    
    @IBAction func MicrosoftLoginAction(_ sender: Any) {
        
        self.micrsoftService?.callGraphAPI(sender as! UIButton)
    }
    

    
    //MARK:- MicrosoftLoginServiceDelegate
    func didAquireToken(token:String?, errror:MicroSoftLoginError?) {
        if let loginError = errror {
            //error found
            print("microsoft Error = \(loginError)")
        } else {
            //login successful
            //setup signin mode info
            SignInMode.setPersistentSignMode(mode:.microsoft)
            
            print("token = \(String(describing: token))")
            self.launchDetailController()
            
        }
    }
    
    func didGetUserDetail(user: Any?, error: MicroSoftLoginError?) {
        
    }
}

