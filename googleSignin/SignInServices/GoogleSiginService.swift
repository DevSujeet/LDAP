//
//  GoogleSiginService.swift
//  googleSignin
//
//  Created by Sujeet.Kumar on 17/03/20.
//  Copyright © 2020 Cuddle. All rights reserved.
//

import Foundation
import GoogleSignIn

protocol GoogleSiginServiceDelegate : class {
    func didGoogleSignIn(user:GIDGoogleUser?, error:Error?)
}

final class GoogleSiginService:NSObject {
    weak var delegate:GoogleSiginServiceDelegate?
    
    private override init() {
        super.init()
        GIDSignIn.sharedInstance().clientID = Constants.GoogleSigninClientID
        GIDSignIn.sharedInstance().delegate = self
    }
    
    class var shared:GoogleSiginService {
        struct singletonWrapper {
            static let singleton = GoogleSiginService()
        }
        
        return singletonWrapper.singleton
    }
    
    func setUp(presentingViewController controller:UIViewController, delegate:GoogleSiginServiceDelegate) {
        self.delegate = delegate
        GIDSignIn.sharedInstance()?.presentingViewController = controller
               
        // Automatically sign in the user.
        GIDSignIn.sharedInstance()?.restorePreviousSignIn()
    }
}

//MARK:- GIDSignInDelegate methods
extension GoogleSiginService:GIDSignInDelegate {
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
//            if (error as NSError).code == GIDSignInErrorCode.hasNoAuthInKeychain.rawValue {
//                print("The user has not signed in before or they have since signed out.")
//            } else {
//                print("\(error.localizedDescription)")
//            }
            
            self.delegate?.didGoogleSignIn(user: nil, error: error)
            return
        }
//        // Perform any operations on signed in user here.
//        let userId = user.userID                  // For client-side use only!
//        let idToken = user.authentication.idToken // Safe to send to the server
//        let fullName = user.profile.name
//        let givenName = user.profile.givenName
//        //        let familyName = user.profile.familyName
//        let email = user.profile.email
//        
//        print("""
//            User detail = \(userId),
//            \(idToken),
//            \(fullName),
//            \(givenName),
//            \(email)
//            """)
        
        self.delegate?.didGoogleSignIn(user: user, error: nil)
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!,
              withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
    }
}
