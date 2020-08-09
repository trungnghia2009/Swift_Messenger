//
//  LoginViewController.swift
//  Messenger
//
//  Created by trungnghia on 7/31/20.
//  Copyright © 2020 trungnghia. All rights reserved.
//

import LBTATools
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import JGProgressHUD

final class LoginViewController: LBTAFormController {

    // MARK: - Properties
    private let spinner = JGProgressHUD(style: .dark)
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.image = #imageLiteral(resourceName: "logo")
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .next
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
        let button = UIButton(type: .system)
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private let facebookLoginButton: FBLoginButton = {
        let button = FBLoginButton()
        button.permissions = ["email, public_profile"] //public_profile: first_name + last_name
        return button
    }()
    
    private let googleLoginButton = GIDSignInButton()
    
    private var loginObserver: NSObjectProtocol?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureUI()
        
        // Notification for passing data
        NotificationCenter.default.addObserver(forName: .didLoginNotification, object: nil, queue: .main) { _ in
            PresenterManager.shared.show(vc: .tabBarController)
        }
    }
    
    // Release memory
    deinit {
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    
    // MARK: - Helpers
    private func configureUI() {
        view.backgroundColor = .systemBackground
        
        emailField.delegate = self
        passwordField.delegate = self
        facebookLoginButton.delegate = self
        GIDSignIn.sharedInstance()?.presentingViewController = self
        
        scrollView.alwaysBounceVertical = true
        formContainerStackView.axis = .vertical
        formContainerStackView.spacing = 10
        formContainerStackView.layoutMargins = .init(top: 20, left: 24, bottom: 0, right: 24)
        
        let size = UIScreen.main.bounds.width / 3
        formContainerStackView.addArrangedSubview(imageView)
        imageView.constrainHeight(size)
        
        formContainerStackView.addArrangedSubview(emailField)
        emailField.constrainHeight(52)
        
        formContainerStackView.addArrangedSubview(passwordField)
        passwordField.constrainHeight(52)
        
        formContainerStackView.addArrangedSubview(loginButton)
        loginButton.constrainHeight(52)
        
        let blankSpace = UIView()
        formContainerStackView.addArrangedSubview(blankSpace)
        blankSpace.constrainHeight(20)
        
        formContainerStackView.addArrangedSubview(facebookLoginButton)
        formContainerStackView.addArrangedSubview(googleLoginButton)
    }
    
    
    private func configureNavigationBar() {
        navigationItem.title = "Log In"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(didTapRegister))
    }
    
    private func alertUserLoginUser() {
        let alert = UIAlertController(title: "Woops",
                                      message: "Please enter all infomation to login",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    // MARK: - Selectors
    @objc private func didTapRegister() {
        let vc = RegisterViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func loginButtonTapped() {
        view.endEditing(false)
        
        guard
            let email = emailField.text,
            let password = passwordField.text,
            !email.isEmpty, !password.isEmpty, password.count >= 6
        else {
            alertUserLoginUser()
            return
        }
        
        spinner.show(in: view)
        
        // Firebase Log In
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { [weak self] (authResult, error) in
            guard let self = self else { return }
            
            self.spinner.dismiss()
            guard let result = authResult, error == nil else {
                print("Error signing in user with email: \(email)")
                return
            }
            
            // Store fullname
            let safeEmail = DatabaseManager.shared.safeEmail(email: email)
            DatabaseManager.shared.getDataFor(path: safeEmail) { (result) in
                switch result {
                case .success(let data):
                    guard let userData = data as? [String: Any],
                        let firstName = userData["first_name"] as? String,
                        let lastName = userData["last_name"] as? String
                    else { return }
                    UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name") // store fullname
                case .failure(let error):
                    print("Failed to read data from firebase, \(error)")
                }
            }
            
            let user = result.user
            print("Logged In user: \(user)")
            PresenterManager.shared.show(vc: .tabBarController)
        }
        
    }


}


// MARK: - UITextFieldDelegate
extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            loginButtonTapped()
        }
        
        return true
    }
}

// MARK: - LoginButtonDelegate for facebook
extension LoginViewController: LoginButtonDelegate {
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        // no operation
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else {
            print("User failed to log in with facebook")
            return
        }
        
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                         parameters: ["fields": "email, first_name, last_name, picture.type(large)"],
                                                         tokenString: token,
                                                         version: nil, httpMethod: .get)
        facebookRequest.start { (_, result, error) in
            guard let result = result as? [String: Any], error == nil else {
                print("Failed to make facebook graph request")
                return
            }
            
            guard let firstName = result["first_name"] as? String,
                let lastName = result["last_name"] as? String,
                let email = result["email"] as? String,
                let picture = result["picture"] as? [String: Any],
                let data = picture["data"] as? [String: Any],
                let pictureUrl = data["url"] as? String else {
                    print("Failed to get email and name from facebook result")
                    return
            }
            
            UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name") // Store fullname
            
            DatabaseManager.shared.userExists(with: email) { (exists) in
                if !exists {
                    let chatUser = ChatAppUser(firstName: firstName,
                                               lastName: lastName,
                                               emailAddress: email)
                    DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                        if success {
                            // upload image
                            
                            /// Download profile image from facebook
                            guard let url = URL(string: pictureUrl) else {
                                print("Failed to get data from Facebook")
                                return
                            }
                            
                            URLSession.shared.dataTask(with: url) { (data, _, _) in
                                guard let data = data else { return }
                                
                                /// Upload image data
                                let fileName = chatUser.profilePictureFileName
                                StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName) { (result) in
                                    switch result {
                                    case .success(let downloadUrl):
                                        UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                        print(downloadUrl)
                                    case .failure(let error):
                                        print("Storage manager error, \(error)")
                                    }
                                }
                            }.resume()
                        }
                    })
                }
            }
            
            
            // Use firebase to login facebook
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            FirebaseAuth.Auth.auth().signIn(with: credential) { (authResult, error) in
                guard authResult != nil, error == nil else {
                    if let error = error {
                        print("Facebook credential login failed, MFA may be needed - \(error.localizedDescription)")
                    }
                    return
                }
                
                print("Successfullt logged user in")
                PresenterManager.shared.show(vc: .tabBarController)
            }
            
        }
        
        
        
    }
    
    
}
