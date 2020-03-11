//
//  DetailPageViewController.swift
//  googleSignin
//
//  Created by Sujeet.Kumar on 11/03/20.
//  Copyright © 2020 Cuddle. All rights reserved.
//

import UIKit
import GoogleSignIn


/// Controller that will be displayed if the user is logged-in.
class DetailPageViewController: UIViewController {
    
    @IBOutlet weak var googleSignOut: UIButton!
    
    @IBAction func googleSignOutAction(_ sender: UIButton) {
        GIDSignIn.sharedInstance().signOut()
        
        //back to the login controller.
        guard let viewController = ViewController.instance() else {return}
        
        
         UIApplication.shared.windows.first?.rootViewController = viewController
         UIApplication.shared.windows.first?.makeKeyAndVisible()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    static func instance() -> DetailPageViewController? {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let detailController = mainStoryboard.instantiateViewController(withIdentifier: "DetailPageViewController") as? DetailPageViewController else {return nil}
        return detailController
    }

}
