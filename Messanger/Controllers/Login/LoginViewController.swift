//
//  LoginViewController.swift
//  Messanger
//
//  Created by Filip Zobic on 5.3.22..
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import Firebase
import JGProgressHUD

final class LoginViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    @objc func setupGoogleLogin() {
        
        guard let clientID: String = FirebaseApp.app()?.options.clientID else {
            return
        }

        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)

        // Start the sign in flow!
        GIDSignIn.sharedInstance.signIn(with: config, presenting: self) { [unowned self] user, error in

            guard error == nil else {
                return
            }
            
            guard let user = user else {
                return
            }
            
            let authentication = user.authentication
            
            guard let idToken = authentication.idToken, let profile = user.profile else {
                return
            }
            
          let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                         accessToken: authentication.accessToken)

            let emailAddress = profile.email
            let fullName = profile.name
            UserDefaults.standard.set(emailAddress, forKey: "email")
            
            
            guard let firstName = profile.givenName,
                  let lastName = profile.familyName else {
                      return
                  }
            UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
            DatabaseManager.shared.userExists(with: emailAddress, completion: {exists in
                if !exists {
                    print("User does not exist")
                    let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: emailAddress)
                    DatabaseManager.shared.insertUser(with: chatUser, completion: {success in
                        if success {
                            // upload image
                            
                            if profile.hasImage {
                                guard let url = user.profile?.imageURL(withDimension: 200) else {
                                    return
                                }
                                URLSession.shared.dataTask(with: url, completionHandler: {data, _, _ in
                                    guard let data = data else {
                                        return
                                    }
                
                                    let fileName = chatUser.profilePictureFileName
                                    StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName, completion: { result in
                                        switch result {
                                        case .success(let downloadUrl):
                                            UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                            print(downloadUrl)
                                        case .failure(let error):
                                            print("Error: \(error)")
                                        }
                                    })
                                }).resume()
                            }
                        }
                    })
                }
            })
            
          print("Google auth works \(credential) \(emailAddress) \(fullName)")
            
            FirebaseAuth.Auth.auth().signIn(with: credential, completion: {[weak self] authResults, error in
                guard let strongSelf = self else {
                    return
                }
                guard authResults != nil, error == nil else {
                    print("Failed loggin in with google credentials")
                    return
                }
                NotificationCenter.default.post(name: .didLogInNotification, object: nil)
                print("Signed in with google")
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            })
        }
    }
    
    private let scrollView: UIScrollView = {
       let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let emailField: UITextField = {
       let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email Address..."
        
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    
    private let passwordField: UITextField = {
       let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password..."
        
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        field.isSecureTextEntry = true
        return field
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let facebookLoginButton: FBLoginButton = {
        let button = FBLoginButton()
        button.permissions = ["public_profile", "email"]
        return button
    }()
    
    private let googleLoginButton: GIDSignInButton = {
        let button = GIDSignInButton()
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Log In"
        view.backgroundColor = .systemBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self,
                                                            action: #selector(didTapRegister))
        
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        googleLoginButton.addTarget(self, action: #selector(setupGoogleLogin), for: .touchUpInside)
        
        emailField.delegate = self
        passwordField.delegate = self
        
        facebookLoginButton.delegate = self
        
        // Add subview
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(facebookLoginButton)
        scrollView.addSubview(googleLoginButton)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = scrollView.width/3
        imageView.frame = CGRect(x: (scrollView.width-size)/2,
                                 y: 20, width: size, height: size)
        emailField.frame = CGRect(x: 30,
                                  y: imageView.bottom+10,
                                  width: scrollView.width-60,
                                  height: 52)
        passwordField.frame = CGRect(x: 30,
                                  y: emailField.bottom+10,
                                  width: scrollView.width-60,
                                  height: 52)
        loginButton.frame = CGRect(x: 30,
                                  y: passwordField.bottom+10,
                                  width: scrollView.width-60,
                                  height: 52)
        facebookLoginButton.frame = CGRect(x: 30,
                                  y: loginButton.bottom+10,
                                  width: scrollView.width-60,
                                  height: 52)
        facebookLoginButton.frame.origin.y = loginButton.bottom+20
        googleLoginButton.frame = CGRect(x: 30,
                                  y: facebookLoginButton.bottom+10,
                                  width: scrollView.width-60,
                                  height: 52)
    }
    
    @objc private func loginButtonTapped() {
        
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text, let password = passwordField.text,
              !email.isEmpty, !password.isEmpty, password.count >= 6 else {
                  alertUserLoginerror()
                  return
              }
        spinner.show(in: view)
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: {[weak self] authResults, error in
            guard let strongSelf = self else {
                return
            }
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            guard let result = authResults, error == nil else {
                print("Failed to login with email: \(email)")
                return
            }
            let user = result.user
            
            let safeEmail = DatabaseManager.safeEmail(email)
            print(safeEmail)
            DatabaseManager.shared.getDataFor(path: safeEmail, completion: { [weak self] result in
                switch result {
                case .success(let data):
                    print(data)
                    guard let userData = data as? [String: Any],
                    let firstName = userData["first_name"] as? String,
                    let lastName = userData["last_name"] as? String else {
                        print("Failed getting user defaults user data")
                        return
                    }
                    UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
                case .failure(let error):
                    print("Failed to read data with error \(error)")
                }
            })
            
            UserDefaults.standard.set(email, forKey: "email")
            
            print("Logged In User: \(user)")
            NotificationCenter.default.post(name: .didLogInNotification, object: nil)
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        })
    }
    
    func alertUserLoginerror() {
        let alert = UIAlertController(title: "Failed", message: "Please enter correct field information", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    @objc private func didTapRegister() {
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField {
            loginButtonTapped()
        }
        
        return true
    }
}

extension LoginViewController: LoginButtonDelegate {
    
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        // no operation
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else {
            print("User failed to login with facebook")
            return
        }
        
        let facebookRequest = FBSDKLoginKit.GraphRequest(
            graphPath: "me",
            parameters: ["fields": "email, first_name, last_name, picture.type(large)"],
            tokenString: token,
            version: nil,
            httpMethod: .get)
        
        facebookRequest.start(completion: { _, result, error in
            guard let result = result as? [String: Any], error == nil else {
                print("Failed to make facebook graph request")
                return
            }
            
            print("\(result)")
            
            guard
                let firstName = result["first_name"] as? String,
                let lastName = result["last_name"] as? String,
                let email = result["email"] as? String,
                let picture = result["picture"] as? [String: Any],
                let data = picture["data"] as? [String: Any],
                let pictureUrl = data["url"] as? String else {
                    print("Failed to get email and name from fb result")
                    return
                }
            UserDefaults.standard.set(email, forKey: "email")
            UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
            
            DatabaseManager.shared.userExists(with: email, completion: {exists in
                if !exists {
                    let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: email)
                    DatabaseManager.shared.insertUser(with: chatUser, completion: {success in
                        if success {
                            
                            guard let url = URL(string: pictureUrl) else {
                                return
                            }
                            
                            URLSession.shared.dataTask(with: url, completionHandler: { data, _, error in
                                guard let data = data else {
                                    return
                                }
                                
                                let fileName = chatUser.profilePictureFileName
                                StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName, completion: { result in
                                    switch result {
                                    case .success(let downloadUrl):
                                        UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
//                                        NotificationCenter.default.post(name: .didLogInNotification, object: nil)
                                        print(downloadUrl)
                                    case .failure(let error):
                                        print("Error: \(error)")
                                    }
                                })
                            }).resume()
                        }
                    })
                }
            })
            
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            FirebaseAuth.Auth.auth().signIn(with: credential, completion: {[weak self] authResult, error in
                guard let strongSelf = self else {
                    return
                }
                
                guard authResult != nil, error == nil else {
                    print("Facebook credential login failed, MFA may be needed")
                    return
                }
                
                print("Logged in facebook user")
                NotificationCenter.default.post(name: .didLogInNotification, object: nil)
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            })
        })
    }
}
