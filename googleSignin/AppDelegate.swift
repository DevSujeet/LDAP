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
import AppAuth
/*
 Google
   https://developers.google.com/identity/sign-in/ios/start-integrating
*/

enum SignInMode:String {
    static let signInKey = "signInKey"
    case google //default
    case microsoft
    case pingFederate
    
    static func getPersistentSignMode() -> SignInMode {
        let userDefault =  UserDefaults.standard
        //1. check if there is value for given key
        guard let rawValue = userDefault.string(forKey: SignInMode.signInKey) else {
            setPersistentSignMode(mode:.google)
            return .google
        }
        //2. check if there is value is a proper enum
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
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    static func getAppDelegate() -> AppDelegate {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate
    }
    
    var signInMode:SignInMode = .google
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
//        configure the GIDSignIn shared instance and set the sign-in delegate.
        // this also ensures that if the user is signed-in--func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) is called which in turn launches te detail screen.
        //be default no such mechanism for microsoft.
        //this means even if the user is signed with microsoft, if he kills the app, the loginView will be launched
        //rather than detailController
        GoogleSiginService.shared
        
        //Check if the user is signed via microsoft accout
        guard let microSoftAccount = MicrosoftLoginService.shared.currentAccount() else {
            //dont do any thing.
            //let it load loginController
            //or google will handle this
            return true
        }
        
        //lauch detail controller
        /* NOTE:
            To enable token caching:
            Ensure your application is properly signed
            Go to your Xcode Project Settings > Capabilities tab > Enable Keychain Sharing
            Click + and enter a following Keychain Groups entry: 3.a For iOS, enter com.microsoft.adalcache 3.b For macOS enter com.microsoft.identity.universalstorage
         */
        self.launchDetailController()
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
        case .pingFederate:
            let pingFederateService = PingFederateLoginService.shared
            guard let currentAuthFlow = pingFederateService.currentAuthorizationFlow else { return false}
            
            if currentAuthFlow.resumeExternalUserAgentFlow(with: url) {
                pingFederateService.currentAuthorizationFlow = nil
                return true
            }
        }
        
        return false
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
    
    //Public method
    func launchDetailController() {
        //launch the detail
        guard let detailController = DetailPageViewController.instance() else {return}
        
        UIApplication.shared.windows.first?.rootViewController = detailController
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }
        
}

