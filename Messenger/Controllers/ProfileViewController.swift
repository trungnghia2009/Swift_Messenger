//
//  ProfileViewController.swift
//  Messenger
//
//  Created by trungnghia on 7/31/20.
//  Copyright © 2020 trungnghia. All rights reserved.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import SDWebImage

final class ProfileViewController: UIViewController {
    
    // MARK: - Properties
    @IBOutlet weak var tableView: UITableView!
    private let email = FirebaseAuth.Auth.auth().currentUser?.email
    private var data = [ProfileViewModel]()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureDataSource()
        configureTableView()
    }
    
    // MARK: - Helpers
    private func configureTableView() {
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: ProfileTableViewCell.reuseIdentifier)
        tableView.tableFooterView = UIView()
        tableView.tableHeaderView = createTableHeader()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func configureDataSource() {
        guard let name = UserDefaults.standard.value(forKey: "name") as? String,
            let email = FirebaseAuth.Auth.auth().currentUser?.email else { return }
        data.append(ProfileViewModel(viewModelType: .info, title: "Name: \(name)", handler: nil))
        data.append(ProfileViewModel(viewModelType: .info, title: "Email: \(email)", handler: nil))
        data.append(ProfileViewModel(viewModelType: .logout, title: "Log Out", handler: { [weak self] in
            self?.logout()
        }))
    }
    
    private func configureNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(didTapEditButton))
    }
    
    private func showAlert(message: String, handler: ((UIAlertAction) -> Void)? ) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .actionSheet)
        let action = UIAlertAction(title: "OK", style: .destructive, handler: handler)
        let cancel = UIAlertAction(title: "CANCEL", style: .cancel, handler: nil)
        alert.addAction(action)
        alert.addAction(cancel)
        present(alert, animated: true)
    }
    
    private func presentLoginController() {
        let vc = LoginViewController()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    private func createTableHeader() -> UIView? {
        guard let email = email else { return nil }
        let safeEmail = DatabaseManager.shared.safeEmail(email: email)
        let fileName = safeEmail + "_profile_picture.png"
        let path = "images/" + fileName
        
        let headerView = UIView(frame: CGRect(x: 0,
                                        y: 0,
                                        width: view.width,
                                        height: 300))
        headerView.backgroundColor = .link
        let imageView = UIImageView(frame: CGRect(x: (headerView.width - 150) / 2,
                                                  y: 75,
                                                  width: 150,
                                                  height: 150))
        imageView.contentMode = .scaleToFill
        imageView.backgroundColor = .white
        imageView.layer.cornerRadius = 75
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 3
        imageView.layer.masksToBounds = true
        headerView.addSubview(imageView)
        
        StorageManager.shared.downloadURL(for: path) { result in
            switch result {
            case .success(let url):
                imageView.sd_setImage(with: url)
            case .failure(let error):
                print("Failed to get download url, \(error.localizedDescription)")
            }
        }
        
        return headerView
    }
    
    private func logout() {
        showAlert(message: "Do you want to log out ?") { _ in
            // Logout facebook
            FBSDKLoginKit.LoginManager().logOut()
            
            // Logout google
            GIDSignIn.sharedInstance()?.signOut()
            
            do {
                try FirebaseAuth.Auth.auth().signOut()
                PresenterManager.shared.show(vc: .loginController)
            } catch {
                print("Failed to log out, \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Selectors
    @objc private func didTapEditButton() {
        
    }

}


// MARK: - UITableViewDataSource
extension ProfileViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = data[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTableViewCell.reuseIdentifier, for: indexPath) as! ProfileTableViewCell
        cell.setup(with: viewModel)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ProfileViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        data[indexPath.row].handler?()
        
    }
}

