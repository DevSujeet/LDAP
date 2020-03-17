//
//  AppDelegate.swift
//  googleSignin
//
//  Created by Sujeet.Kumar on 27/02/20.
//  Copyright © 2020 Cuddle. All rights reserved.
//

import UIKit
import GoogleSignIn
import MSAL
/*
 Google
   https://developers.google.com/identity/sign-in/ios/start-integrating
*/

enum SignInMode:String {
    static let signInKey = "signInKey"
    case google //default
    case microsoft
    
    static func getPersistentSignMode() -> SignInMode {
        let userDefault =  UserDefaults.standard
        guard let rawValue = userDefault.string(forKey: SignInMode.signInKey) else {
            setPersistentSignMode(mode:.google)
            return .google
        }
        guard let mode = SignInMode(rawValue: rawValue) else {
            setPersistentSignMode(mode:.google)
            return .google
        }
        
        return mode
    }
    
    static func setPersistentSignMode(mode:SignInMode) {
        let rawValue = mode.rawValue
        let userDefault =  UserDefaults.standard
        userDefault.set(rawValue, forKey: SignInMode.signInKey)
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate,GIDSignInDelegate {
    
    var signInMode:SignInMode = .google
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        //configure the GIDSignIn shared instance and set the sign-in delegate.
        GIDSignIn.sharedInstance().clientID = Constants.GoogleSigninClientID
        GIDSignIn.sharedInstance().delegate = self
        return true
    }
    
    @available(iOS 9.0, *)
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        let signInMode = SignInMode.getPersistentSignMode()
        switch signInMode {
        case .google:
            return GIDSignIn.sharedInstance()?.handle(url) ?? true
        case .microsoft:
            return MSALPublicClientApplication.handleMSALResponse(url, sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String)
        }
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    //MARK:- GIDSignInDelegate methods
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            if (error as NSError).code == GIDSignInErrorCode.hasNoAuthInKeychain.rawValue {
                print("The user has not signed in before or they have since signed out.")
            } else {
                print("\(error.localizedDescription)")
            }
            return
        }
        // Perform any operations on signed in user here.
        let userId = user.userID                  // For client-side use only!
        let idToken = user.authentication.idToken // Safe to send to the server
        let fullName = user.profile.name
        let givenName = user.profile.givenName
        //        let familyName = user.profile.familyName
        let email = user.profile.email
        
        print("""
            User detail = \(userId),
            \(idToken),
            \(fullName),
            \(givenName),
            \(email)
            """)
        
        self.launchDetailController()
    }
    
    private func launchDetailController() {
        //launch the detail
        guard let detailController = DetailPageViewController.instance() else {return}
        
        UIApplication.shared.windows.first?.rootViewController = detailController
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!,
              withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
    }
}

