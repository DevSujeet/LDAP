//
//  PingFederateLoginService.swift
//  ThirdPartySignin
//
//  Created by Sujeet.Kumar on 06/04/20.
//  Copyright © 2020 Cuddle. All rights reserved.
//

import Foundation

protocol PingFederateSigninProtocol : class {
    func didSignin(withToken token:String, error:Error?)
}

class PingFederateLoginService {
    weak var delegate:PingFederateSigninProtocol?
}


