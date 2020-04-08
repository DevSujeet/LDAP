//
//  PingFederateLoginService.swift
//  ThirdPartySignin
//
//  Created by Sujeet.Kumar on 06/04/20.
//  Copyright © 2020 Cuddle. All rights reserved.
//

import Foundation
import AppAuth
///Object to hold the information about the pingFedrate organization details.
/// each organization can have different detail.
/// This object will be passed to the PingFederateLoginService to enable organozation specific OAuth.
/*
 AUTHORIZATION URL    https://auth.pingone.asia/9095f36c-d2c4-43b1-b5f0-593982b6d600/as/authorize
 TOKEN ENDPOINT    https://auth.pingone.asia/9095f36c-d2c4-43b1-b5f0-593982b6d600/as/token
 JWKS ENDPOINT    https://auth.pingone.asia/9095f36c-d2c4-43b1-b5f0-593982b6d600/as/jwks
 USERINFO ENDPOINT    https://auth.pingone.asia/9095f36c-d2c4-43b1-b5f0-593982b6d600/as/userinfo
 SIGNOFF ENDPOINT    https://auth.pingone.asia/9095f36c-d2c4-43b1-b5f0-593982b6d600/as/signoff
 OIDC DISCOVERY ENDPOINT    https://auth.pingone.asia/9095f36c-d2c4-43b1-b5f0-593982b6d600/as/.well-known/openid-configuration
 ISSUER    https://auth.pingone.asia/9095f36c-d2c4-43b1-b5f0-593982b6d600/as
 CLIENT ID    fcc46ce6-149c-4774-b013-9c97a97fe589
 CLIENT SECRET    dUZYKScTNBfY7XicWrysFnh0xKw8ziJ.nLUwvMWvmpotK6xlYgPQJdZjCZQ_taQE
 */

enum PingFederateLoginError:Error {
    case couldNotAcquireToken
    case userInfoEndpointNotFound
    case lastAccessTokenNotFound
    case errorFetchingFreshTokens
    
    case nonHTTPResponseError
    case couldNotDeserializeResult
    case authorizationError
    case otherNetworkError
    

}
class PingFederateConfig {
    /// @brief The OIDC issuer from which the configuration will be discovered.
    /// @discussion This is your base PingFederate server URL.
    var kIssuer: String? = "https://auth.pingone.asia/9095f36c-d2c4-43b1-b5f0-593982b6d600/as"
    
    /// The OAuth client ID.
    /// @discussion This is configured in your PingFederate administration console under OAuth Settings > Client Management. The example "ac_client" from the OAuth playground can be used here.
    var kClientID: String? = "fcc46ce6-149c-4774-b013-9c97a97fe589"
    
    /// The OAuth redirect URI for the client @c kClientID.
    /// @discussion The redirect URI that PingFederate will send the user back to after the authorization step. To avoid collisions, this should be a reverse domain formatted string. You must define this in your OAuth client in PingFederate.
    var KRedirectURI:String? = "pingidsdksample://cb"
    
    /// kAppAuthExampleAuthStateKey
    /// @brief NSCoding key for the authState property.
    var kAppAuthExampleAuthStateKey:String? = "kAppAuthExampleAuthStateKey" //can use any string as key.
    
    var kClientSecret:String?// = "dUZYKScTNBfY7XicWrysFnh0xKw8ziJ.nLUwvMWvmpotK6xlYgPQJdZjCZQ_taQE"
    
}

protocol PingFederateSigninProtocol : class {
    func didSignin(withToken token:String?, error:PingFederateLoginError?)
    func didGetUserDetail(user: Any?, error: PingFederateLoginError?)
}

class PingFederateLoginService : NSObject {
    
    private override init() {
        super.init()
    }
    
    class var shared:PingFederateLoginService {
        struct singletonWrapper {
            static let singleton = PingFederateLoginService()
        }
        
        return singletonWrapper.singleton
    }
    
    func setUp(withConfig config:PingFederateConfig,
         presentingController controller:UIViewController,
         delegate:PingFederateSigninProtocol) {
        
        self.config = config
        self.delegate = delegate
        self.presentingViewController = controller
    }
    
    private weak var presentingViewController:UIViewController!
    private weak var delegate:PingFederateSigninProtocol?
    var accessToken:String?
    
    private var config:PingFederateConfig!
    ///The authorization state. This is the AppAuth object that you should keep around and
    ///serialize to disk.
     private var authState:OIDAuthState?
    /// The authorization flow session which receives the return URL from SFSafariViewController.
    /// @discussion We need to store this in the app delegate as it's that delegate which receives the
    /// incoming URL on UIApplicationDelegate.application:openURL:options:. This property will be
    /// nil, except when an authorization flow is in progress.
    var currentAuthorizationFlow:OIDExternalUserAgentSession?
    
    //MARK:- Public method
    
    public func actionSignIn() {
        let issuer = URL(string: config.kIssuer!)!
        let redirectURI = URL(string: config.KRedirectURI!)!
        
        self.logMessage(message: "Fetching configuration for issuer: \(issuer)")
        
        // discovers endpoints
        //configuration = OIDServiceConfiguration
        OIDAuthorizationService.discoverConfiguration(forIssuer: issuer) { (configuration, error) in
            
            if !(configuration != nil) {
                self.logMessage(message: "Error retrieving discovery document: \(error?.localizedDescription)")
                self.setAuthState(authState: nil)
                return
            }
            
            self.logMessage(message: "Got configuration: \(configuration)")
            
            // NOTE: PingFederate 8.1 and earlier do not support the S256 PKCE challenge method
            // therefore we must manually configure PKCE to use the plain method and set a
            // code_challenge and code_verifier parameter.
            let code_challenge_method = "plain"
            let code_verifier = OIDAuthorizationRequest.generateCodeVerifier()
            let state = OIDAuthorizationRequest.generateState()
            
            // OPTIONAL: You can include additional parameters to the authorization request
            // by including them in the additionalParameters parameters. Set this to nil if
            // you have no additional parameters. The example below sets the "acr_values" param
            // to urn:acr:form.
            var additionalParams:[String:String]? = [:]
//            additionalParams!["acr_values"] = "urn:acr:form"
            
            additionalParams = nil
            
            // builds authentication request
            let request:OIDAuthorizationRequest = OIDAuthorizationRequest.init(configuration: configuration!,
                                                                               clientId: self.config.kClientID!,
                                                                               clientSecret: self.config.kClientSecret,
                                                                               scope: "openid profile email address phone",
                                                                               redirectURL: redirectURI,
                                                                               responseType: OIDResponseTypeCode,
                                                                               state: state,
                                                                               nonce: nil,
                                                                               codeVerifier: code_verifier,
                                                                               codeChallenge: code_verifier,
                                                                               codeChallengeMethod: code_challenge_method,
                                                                               additionalParameters: additionalParams)
            
            // performs authentication request
            
            self.logMessage(message: "Initiating authorization request with scope: \(request.scope)")
            
            let authFlow = OIDAuthState.authState(byPresenting: request,
                                                        presenting: self.presentingViewController,
                                                        callback: { (oidAuthState, error) in
                                                            if let authState = oidAuthState {
                                                                self.setAuthState(authState: authState)
                                                                self.accessToken = authState.lastTokenResponse?.accessToken
                                                                self.logMessage(message: "Got authorization tokens. Access token: \(self.accessToken)")
                                                                self.delegate?.didSignin(withToken: self.accessToken!, error: nil)
                                                                self.actionCallUserInfo()
                                                                
                                                            } else {
                                                                self.logMessage(message: "Authorization error: \(error?.localizedDescription)")
                                                                self.delegate?.didSignin(withToken: nil, error: .couldNotAcquireToken)
                                                                self.setAuthState(authState: nil)
                                                            }
            })
            
            self.currentAuthorizationFlow = authFlow
        }
    }
    
    
    private  func actionCallUserInfo() {
        guard let userinfoEndpoint =
            (self.authState?.lastAuthorizationResponse.request.configuration.discoveryDocument?.userinfoEndpoint) else {
                self.delegate?.didGetUserDetail(user: nil, error: .userInfoEndpointNotFound)
                self.logMessage(message: "Userinfo endpoint not declared in discovery document")
                return
        }
        
        guard let currentAccessToken = self.authState?.lastTokenResponse?.accessToken else {
            self.delegate?.didGetUserDetail(user: nil, error: .lastAccessTokenNotFound)
            self.logMessage(message: "accessToken not found while getting userInfo.")
            return
        }
        
        self.logMessage(message: "Performing userinfo request")

        self.authState?.performAction(freshTokens: { (accessToken, idToken, error) in
            if error != nil {
                self.delegate?.didGetUserDetail(user: nil, error: .errorFetchingFreshTokens)
                self.logMessage(message: "Error fetching fresh tokens: \(error!.localizedDescription)");
                return;
            }
            
            if (currentAccessToken != accessToken) {
                self.logMessage(message: "Access token was refreshed automatically \(currentAccessToken) to \(accessToken)")
            } else {
                self.logMessage(message: "Access token was fresh and not updated \(accessToken)")
            }
            
            //// creates request to the userinfo endpoint, with access token in the Authorization header
            var request = URLRequest.init(url: userinfoEndpoint)
            let authorizationHeaderValue = "Bearer \(accessToken!)"
            
            request.addValue(authorizationHeaderValue, forHTTPHeaderField: "Authorization")
            
            let defaultSession = URLSession(configuration: .default)
            
            var dataTask: URLSessionDataTask?
            
            // 1
            dataTask?.cancel()
            
            dataTask = defaultSession.dataTask(with: request,
                                               completionHandler: { (data, response, error) in
                                                
                                                DispatchQueue.main.async {
                                                    guard let httpResponse = response as? HTTPURLResponse else {
                                                        self.delegate?.didGetUserDetail(user: nil, error: .nonHTTPResponseError)
                                                        self.logMessage(message:"Non-HTTP response \(error)")
                                                        return;
                                                    }
                                                    
                                                    var jsonDictionaryOrArray:[String: Any]?
                                                    do {
                                                        // make sure this JSON is in the format we expect
                                                        if let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any] {
                                                            jsonDictionaryOrArray = json
                                                        }
                                                    } catch let error as NSError {
                                                        self.delegate?.didGetUserDetail(user: nil, error: .couldNotDeserializeResult)
                                                        self.logMessage(message:"Failed to load: \(error.localizedDescription)")
                                                    }
                                                    //
                                                    
                                                    if (httpResponse.statusCode != 200) {
                                                        // server replied with an error
                                                        let responseText = String(data: data!, encoding: String.Encoding.utf8)
                                                        
                                                        if (httpResponse.statusCode == 401) {
                                                            // "401 Unauthorized" generally indicates there is an issue with the authorization
                                                            // grant. Puts OIDAuthState into an error state.
                                                            let oAuthError = OIDErrorUtilities.resourceServerAuthorizationError(withCode: 0,
                                                                                                                                errorResponse: jsonDictionaryOrArray,
                                                                                                                                underlyingError: error)
                                                            
                                                            self.authState?.update(withAuthorizationError: oAuthError)
                                                            
                                                            self.delegate?.didGetUserDetail(user: nil, error: .authorizationError)
                                                            self.logMessage(message: "Authorization Error \(oAuthError). \n Response \(responseText)")
                                                        } else {
                                                             self.delegate?.didGetUserDetail(user: nil, error: .otherNetworkError)
                                                            self.logMessage(message: "HTTP: \(httpResponse.statusCode). \n Response \(responseText)")
                                                        }
                                                        return
                                                    }
                                                    
                                                    //// success response
                                                    self.delegate?.didGetUserDetail(user: jsonDictionaryOrArray, error: nil)
                                                    self.logMessage(message: "SUCCESS with USERINfo: \(jsonDictionaryOrArray).")
                                                }
                                                
            })
            
            dataTask?.resume()
            
        }, additionalRefreshParameters: nil)
        
        
        
    }
    /// cay be used to logout the user from device.
    public func actionClearAuthenticatedState() {
        self.authState?.setNeedsTokenRefresh()
        self.setAuthState(authState: nil)
        
    }
    
    //MARK:- Private methods
    private func UpdateUI() {
        
    }
    
    /// for production usage consider using the OS Keychain instead
    private func saveState() {
        let key = self.config.kAppAuthExampleAuthStateKey!
        let userDefault = UserDefaults.standard
        guard let currentAuthState = self.authState else {
            print("trying to save nil authState, can lead to crash")
            return
        }
        do {
            let archivedAuthStateData = try NSKeyedArchiver.archivedData(withRootObject: self.authState!, requiringSecureCoding: true)
            userDefault.set(archivedAuthStateData, forKey: key)
            userDefault.synchronize()
        } catch {
            logMessage(message: "archivedData failed saving state.")
        }
        
        
        //        NSData *archivedAuthState = [ NSKeyedArchiver archivedDataWithRootObject:_authState];
        //        [[NSUserDefaults standardUserDefaults] setObject:archivedAuthState
        //                                                  forKey:kAppAuthExampleAuthStateKey];
        //        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    /// loads OIDAuthState from NSUSerDefaults
    private func loadState() {
        let key = self.config.kAppAuthExampleAuthStateKey!
        let userDefault = UserDefaults.standard
        let archivedAuthState = userDefault.object(forKey: key)
        var savedAuthState:OIDAuthState?
        do {
            if let authState = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(archivedAuthState as! Data) as? OIDAuthState {
                savedAuthState = authState
            } else {
                logMessage(message: "1/loadState failed while unarchiveTopLevelObjectWithData")
            }
        } catch {
            logMessage(message: "2/loadState failed while unarchiveTopLevelObjectWithData")
            return
        }
        
        self.setAuthState(authState: savedAuthState!)
    }
    
    private func setAuthState(authState:OIDAuthState?) {
        self.authState = authState
        self.authState?.stateChangeDelegate = self
        self.stateChanged()
    }
    
    private func stateChanged() {
        self.saveState()
        self.UpdateUI()
    }
    
    private func logMessage(message:Any?) {
        print("#####################Log PingFederate#######################")
        print(message ?? "error mesage log failed")
        print("#####################END#######################")
    }
}


extension PingFederateLoginService:OIDAuthStateChangeDelegate,OIDAuthStateErrorDelegate {
    func didChange(_ state: OIDAuthState) {
        self.stateChanged()
    }
    
    func authState(_ state: OIDAuthState, didEncounterAuthorizationError error: Error) {
        self.logMessage(message: "didEncounterAuthorizationError \(error.localizedDescription)")
    }
    
    
}
