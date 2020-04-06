//
//  MicrosoftLoginController.swift
//  googleSignin
//
//  Created by Sujeet.Kumar on 11/03/20.
//  Copyright © 2020 Cuddle. All rights reserved.
//

import Foundation
import MSAL
/*
    https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-v2-ios
 
 // edit info.plist
 Finally, your app must have an LSApplicationQueriesSchemes entry in your Info.plist alongside the CFBundleURLTypes. The sample comes with this included.

 <key>LSApplicationQueriesSchemes</key>
 <array>
    <string>msauthv2</string>
    <string>msauthv3</string>
 </array>
 */
protocol MicrosoftLoginServiceDelegate:class {
    func didAquireToken(token:String?, errror:MicroSoftLoginError?)
    func didGetUserDetail(user:Any?, error:MicroSoftLoginError?)
}

enum MicroSoftLoginError:Error {
    case couldNotAcquireToken
    case noResultFound
    case couldNotAcquireTokenSilently
    //---error in gettting user detail
    case couldNotDeserializeResult
    case couldNotGetResult
}

final class MicrosoftLoginService {

    // Update the below to your client ID you received in the portal. The below is for running the demo only
    let kClientID = "1fd8f856-02c9-4ad0-b146-13c049b33df8"
    let kRedirectUri = "msauth.ai.cuddle.googleSignin://auth"
    let kAuthority = "https://login.microsoftonline.com/common"
    let kGraphEndpoint = "https://graph.microsoft.com/"
    
//    let kClientID = "66855f8a-60cd-445e-a9bb-8cd8eadbd3fa"
//    let kGraphEndpoint = "https://graph.microsoft.com/"
//    let kAuthority = "https://login.microsoftonline.com/common"
    
    let kScopes: [String] = ["user.read"]
    
    var accessToken = String()
    var applicationContext : MSALPublicClientApplication?
    var webViewParamaters : MSALWebviewParameters?
    
    var parentViewController:UIViewController!
    weak var delegate:MicrosoftLoginServiceDelegate?
    
    private init() {
        
    }
    
    class var shared:MicrosoftLoginService {
        struct singletonWrapper {
            static let singleton = MicrosoftLoginService()
        }
        
        return singletonWrapper.singleton
    }
    
    func setUp(withParentController viewController:UIViewController, delegate:MicrosoftLoginServiceDelegate) {
        self.delegate = delegate
        self.parentViewController = viewController
        do {
            try self.initMSAL()
        } catch let error {
            self.updateLogging(text: "Unable to create Application Context \(error)")
        }
    }
}


// MARK: Initialization

extension MicrosoftLoginService {
    
    /**
     
     Initialize a MSALPublicClientApplication with a given clientID and authority
     
     - clientId:            The clientID of your application, you should get this from the app portal.
     - redirectUri:         A redirect URI of your application, you should get this from the app portal.
     If nil, MSAL will create one by default. i.e./ msauth.<bundleID>://auth
     - authority:           A URL indicating a directory that MSAL can use to obtain tokens. In Azure AD
     it is of the form https://<instance/<tenant>, where <instance> is the
     directory host (e.g. https://login.microsoftonline.com) and <tenant> is a
     identifier within the directory itself (e.g. a domain associated to the
     tenant, such as contoso.onmicrosoft.com, or the GUID representing the
     TenantID property of the directory)
     - error                The error that occurred creating the application object, if any, if you're
     not interested in the specific error pass in nil.
     */
    func initMSAL() throws {
        
        guard let authorityURL = URL(string: kAuthority) else {
            self.updateLogging(text: "Unable to create authority URL")
            return
        }
        
        let authority = try MSALAADAuthority(url: authorityURL)
        
        let msalConfiguration = MSALPublicClientApplicationConfig(clientId: kClientID, redirectUri: nil, authority: authority)
        self.applicationContext = try MSALPublicClientApplication(configuration: msalConfiguration)
        
        self.webViewParamaters = MSALWebviewParameters(parentViewController: self.parentViewController!)
    }
    
    func initWebViewParams() {
        self.webViewParamaters = MSALWebviewParameters(parentViewController: self.parentViewController!)
    }
}


//MARK:- Acquiring and using token
extension MicrosoftLoginService {
    
    /**
     This will invoke the authorization flow.
     */
    @objc func callGraphAPI(_ sender: UIButton) {
        
        guard let currentAccount = self.currentAccount() else {
            // We check to see if we have a current logged in account.
            // If we don't, then we need to sign someone in.
            acquireTokenInteractively()
            return
        }
        
        acquireTokenSilently(currentAccount)
    }
    
    func acquireTokenInteractively() {
        
        guard let applicationContext = self.applicationContext else { return }
        guard let webViewParameters = self.webViewParamaters else { return }

        let parameters = MSALInteractiveTokenParameters(scopes: kScopes, webviewParameters: webViewParameters)
        parameters.promptType = .selectAccount;
        
        applicationContext.acquireToken(with: parameters) { (result, error) in
            
            if let error = error {
                self.delegate?.didAquireToken(token: nil, errror: .couldNotAcquireToken)
                self.updateLogging(text: "Could not acquire token: \(error)")
                return
            }
            
            guard let result = result else {
                self.delegate?.didAquireToken(token: nil, errror: .noResultFound)
                self.updateLogging(text: "Could not acquire token: No result returned")
                return
            }
            
            self.accessToken = result.accessToken
            self.updateLogging(text: "Access token is \(self.accessToken)")
            self.updateSignOutButton(enabled: true)
            
            self.delegate?.didAquireToken(token: self.accessToken, errror: nil)
            
            //call this below method if user detail is to be acuired using GraphAPI
//            self.getContentWithToken()
        }
    }
    
    func acquireTokenSilently(_ account : MSALAccount!) {
        
        guard let applicationContext = self.applicationContext else { return }
        
        /**
         
         Acquire a token for an existing account silently
         
         - forScopes:           Permissions you want included in the access token received
         in the result in the completionBlock. Not all scopes are
         guaranteed to be included in the access token returned.
         - account:             An account object that we retrieved from the application object before that the
         authentication flow will be locked down to.
         - completionBlock:     The completion block that will be called when the authentication
         flow completes, or encounters an error.
         */
        
        let parameters = MSALSilentTokenParameters(scopes: kScopes, account: account)
        
        applicationContext.acquireTokenSilent(with: parameters) { (result, error) in
            
            if let error = error {
                
                let nsError = error as NSError
                
                // interactionRequired means we need to ask the user to sign-in. This usually happens
                // when the user's Refresh Token is expired or if the user has changed their password
                // among other possible reasons.
                
                if (nsError.domain == MSALErrorDomain) {
                    
                    if (nsError.code == MSALError.interactionRequired.rawValue) {
                        
                        DispatchQueue.main.async {
                            self.acquireTokenInteractively()
                        }
                        return
                    }
                }
                
                self.updateLogging(text: "Could not acquire token silently: \(error)")
                self.delegate?.didAquireToken(token: nil, errror: .couldNotAcquireTokenSilently)
                return
            }
            
            guard let result = result else {
                self.delegate?.didAquireToken(token: nil, errror: .noResultFound)
                self.updateLogging(text: "Could not acquire token: No result returned")
                return
            }
            
            self.accessToken = result.accessToken
            self.updateLogging(text: "Refreshed Access token is \(self.accessToken)")
            self.updateSignOutButton(enabled: true)
            
            self.delegate?.didAquireToken(token: self.accessToken, errror: nil)
            
            //call this below method if user detail is to be acuired using GraphAPI
//            self.getContentWithToken()
        }
    }
    
    func getGraphEndpoint() -> String {
        return kGraphEndpoint.hasSuffix("/") ? (kGraphEndpoint + "v1.0/me/") : (kGraphEndpoint + "/v1.0/me/");
    }
    
    /**
     This will invoke the call to the Microsoft Graph API. It uses the
     built in URLSession to create a connection.
     */
    func getContentWithToken() {
        
        // Specify the Graph API endpoint
        let graphURI = getGraphEndpoint()
        let url = URL(string: graphURI)
        var request = URLRequest(url: url!)
        
        // Set the Authorization header for the request. We use Bearer tokens, so we specify Bearer + the token we got from the result
        request.setValue("Bearer \(self.accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let error = error {
                self.updateLogging(text: "Couldn't get graph result: \(error)")
                self.delegate?.didGetUserDetail(user: nil, error:.couldNotGetResult)
                return
            }
            
            guard let result = try? JSONSerialization.jsonObject(with: data!, options: []) else {
                self.delegate?.didGetUserDetail(user: nil, error:.couldNotDeserializeResult)
                self.updateLogging(text: "Couldn't deserialize result JSON")
                return
            }
            
            self.delegate?.didGetUserDetail(user: result, error:nil)
            self.updateLogging(text: "Result from Graph: \(result))")
            
            }.resume()
    }

}


// MARK: Get account and removing cache

extension MicrosoftLoginService {
    func currentAccount() -> MSALAccount? {
        
        guard let applicationContext = self.applicationContext else { return nil }
        
        // We retrieve our current account by getting the first account from cache
        // In multi-account applications, account should be retrieved by home account identifier or username instead
        
        do {
            
            let cachedAccounts = try applicationContext.allAccounts()
            
            if !cachedAccounts.isEmpty {
                return cachedAccounts.first
            }
            
        } catch let error as NSError {
            
            self.updateLogging(text: "Didn't find any accounts in cache: \(error)")
        }
        
        return nil
    }
    
    /**
     This action will invoke the remove account APIs to clear the token cache
     to sign out a user from this application.
     */
    @objc func signOut() {
        
        guard let applicationContext = self.applicationContext else { return }
        
        guard let account = self.currentAccount() else { return }
        
        do {
            
            /**
             Removes all tokens from the cache for this application for the provided account
             
             - account:    The account to remove from the cache
             */
            
            try applicationContext.remove(account)
            self.updateLogging(text: "")
            self.updateSignOutButton(enabled: false)
            self.accessToken = ""
            
        } catch let error as NSError {
            
            self.updateLogging(text: "Received error signing account out: \(error)")
        }
    }
}


// MARK: UI Helpers
extension MicrosoftLoginService {
    
//    func initUI() {
//        // Add call Graph button
//        callGraphButton  = UIButton()
//        callGraphButton.translatesAutoresizingMaskIntoConstraints = false
//        callGraphButton.setTitle("Call Microsoft Graph API", for: .normal)
//        callGraphButton.setTitleColor(.blue, for: .normal)
//        callGraphButton.addTarget(self, action: #selector(callGraphAPI(_:)), for: .touchUpInside)
//        self.view.addSubview(callGraphButton)
//
//        callGraphButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
//        callGraphButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 50.0).isActive = true
//        callGraphButton.widthAnchor.constraint(equalToConstant: 300.0).isActive = true
//        callGraphButton.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
//
//        // Add sign out button
//        signOutButton = UIButton()
//        signOutButton.translatesAutoresizingMaskIntoConstraints = false
//        signOutButton.setTitle("Sign Out", for: .normal)
//        signOutButton.setTitleColor(.blue, for: .normal)
//        signOutButton.setTitleColor(.gray, for: .disabled)
//        signOutButton.addTarget(self, action: #selector(signOut(_:)), for: .touchUpInside)
//        self.view.addSubview(signOutButton)
//
//        signOutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
//        signOutButton.topAnchor.constraint(equalTo: callGraphButton.bottomAnchor, constant: 10.0).isActive = true
//        signOutButton.widthAnchor.constraint(equalToConstant: 150.0).isActive = true
//        signOutButton.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
//
//        // Add logging textfield
//        loggingText = UITextView()
//        loggingText.isUserInteractionEnabled = false
//        loggingText.translatesAutoresizingMaskIntoConstraints = false
//
//        self.view.addSubview(loggingText)
//
//        loggingText.topAnchor.constraint(equalTo: signOutButton.bottomAnchor, constant: 10.0).isActive = true
//        loggingText.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 10.0).isActive = true
//        loggingText.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: 10.0).isActive = true
//        loggingText.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 10.0).isActive = true
//    }
    
    func updateLogging(text : String) {

        if Thread.isMainThread {
            logResponse(text : text)
        } else {
            DispatchQueue.main.async {
                self.logResponse(text : text)
            }
        }
    }
    
    func updateSignOutButton(enabled : Bool) {
        if Thread.isMainThread {
            self.updateSignOutStatus(enabled : enabled)
        } else {
            DispatchQueue.main.async {
                self.updateSignOutStatus(enabled : enabled)
            }
        }
    }
    
    private func logResponse(text : String) {
        print("#####################Log#######################")
        print(text)
        print("#####################END#######################")
    }
    private func updateSignOutStatus(enabled : Bool) {
        print("delegate to app when the user is logged out!!")

    }
}
