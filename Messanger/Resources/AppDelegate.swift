//
//  AppDelegate.swift
//  Messanger
//
//  Created by Filip Zobic on 5.3.22..
//

import UIKit
import FBSDKLoginKit
import Firebase
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
    FirebaseApp.configure()
    ApplicationDelegate.shared.application(
        application,
        didFinishLaunchingWithOptions: launchOptions
    )
//    GIDSignIn.sharedInstance()?.clientID = FirebaseApp.app()?.options.clientID
//    GIDSignIn.sharedInstance()?.delegate = self

    
    
    return true
}
      
func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
        return GIDSignIn.sharedInstance.handle(url)
    }
    
//    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
//        guard error == nil else {
//            return
//        }
//
//        guard let authentication = user.authentication else { return }
//
//        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
//
//
//    }
//
//    func sign(_ signIn: GIDSignIn!, didDisconnectNotificationWith user: GIDGoogleUser!, withError error: Error!) {
//
//    }
    
}

