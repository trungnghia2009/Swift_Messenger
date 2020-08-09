//
//  ViewController.swift
//  Messenger
//
//  Created by trungnghia on 7/31/20.
//  Copyright © 2020 trungnghia. All rights reserved.
//

import UIKit
import FirebaseAuth
import JGProgressHUD
import SDWebImage

final class ConversationsViewController: UIViewController {

    // MARK: - Properties
    private let spinner = JGProgressHUD(style: .dark)
    private let tableView = UITableView()
    
    private var conversations = [Conversation]()
    
    private let noConversationsLabel: UILabel = {
        let label = UILabel()
        label.text = "No Conversations!"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.isHidden = false
        return label
    }()
    
    private let profileImageView = ProfileImageView(frame: .zero)
    
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        validateAuth()
        configureNavigationBar()
        configureUI()
        configureTableView()
        startListeningForConversations()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noConversationsLabel.frame = CGRect(x: view.width / 4,
                                            y: (view.height - 200) / 2,
                                            width: view.width / 2,
                                            height: 200)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    
    // MARK: - Helpers
    private func configureNavigationBar() {
        navigationItem.title = "Chats"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose,
                                                            target: self,
                                                            action: #selector(didTapComposeButton))
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: profileImageView)
        profileImageView.delegate = self
        
        guard let currentEmail = FirebaseAuth.Auth.auth().currentUser?.email else { return }
        let safeEmail = DatabaseManager.shared.safeEmail(email: currentEmail)
        
        let path = "images/\(safeEmail)_profile_picture.png"
        StorageManager.shared.downloadURL(for: path) { [weak self] result in
            switch result {
            case .success(let url):
                self?.profileImageView.url = url
            case .failure(let error):
                print("Cannot get profile image, \(error)")
                self?.profileImageView.image = UIImage(systemName: "person")
            }
        }
    }
    
    private func configureTableView() {
        tableView.isHidden = true
        tableView.register(ConversationCell.self, forCellReuseIdentifier: ConversationCell.reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func configureUI() {
        view.addSubview(tableView)
        view.addSubview(noConversationsLabel)
    }
    
    private func startListeningForConversations() {
        guard let currentEmail = FirebaseAuth.Auth.auth().currentUser?.email else { return }
        let safeEmail = DatabaseManager.shared.safeEmail(email: currentEmail)
        
        DatabaseManager.shared.getAllConversations(for: safeEmail) { [weak self] (result) in
            guard let self = self else { return }
            
            switch result {
            case .success(let conversations):
                guard !conversations.isEmpty else {
                    self.noConversationsLabel.isHidden = false
                    self.tableView.isHidden = true
                    return
                }
                
                self.conversations = conversations
                self.noConversationsLabel.isHidden = true
                self.tableView.isHidden = false
                self.tableView.reloadData()
                
            case .failure(let error):
                print("Failed to get all conversations, \(error.localizedDescription)")
                self.tableView.isHidden = true
                self.noConversationsLabel.isHidden = false
            }
        }
    }
     
    private func validateAuth() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
            PresenterManager.shared.show(vc: .loginController)
        }
    }
    
    private func createNewConversation(result: SearchResult) {
        let name = result.name
        let email = result.email
        
        // Check in database if conversation with these two users exists
        // if it does, reuse conversation id
        // otherwise use existing code
        DatabaseManager.shared.getConversationId(with: email) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let conversationId):
                if conversationId == nil {
                    print("I am in...")
                    let vc = ChatViewController(with: email, id: nil)
                    vc.isNewConveration = true
                    vc.title = name
                    vc.navigationItem.largeTitleDisplayMode = .never
                    self.navigationController?.pushViewController(vc, animated: true)
                } else {
                    let vc = ChatViewController(with: email, id: conversationId)
                    vc.title = name
                    vc.navigationItem.largeTitleDisplayMode = .never
                    self.navigationController?.pushViewController(vc, animated: true)
                }
                
            case .failure(let error):
                print("Failed to fetch data or there is no conversation , \(error)")
                let vc = ChatViewController(with: email, id: nil)
                vc.isNewConveration = true
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
        
    }
    
    // MARK: - Selectors
    @objc private func didTapComposeButton() {
        let vc = NewConversationViewController()
        vc.completion = { [weak self] result in
            guard let self = self else { return }
            
            let currentConversations = self.conversations
            
            if let targetConversation = currentConversations.first(where: { $0.otherUserEmail == result.email }) {
                // Go to existing conversation
                let vc = ChatViewController(with: targetConversation.otherUserEmail, id: targetConversation.id)
                vc.title = result.name
                vc.navigationItem.largeTitleDisplayMode = .never
                self.navigationController?.pushViewController(vc, animated: true)
            } else {
                // Create new conversation
                self.createNewConversation(result: result)
            }
            
            
        }
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }

}

// MARK: - UITableViewDataSource
extension ConversationsViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = conversations[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationCell.reuseIdentifier, for: indexPath) as! ConversationCell
        cell.configure(with: model)
        return cell
    }
    
}

// MARK: - UITableViewDelegate
extension ConversationsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = conversations[indexPath.row]
        openConversation(model)
    }
    
    private func openConversation(_ model: Conversation) {
        let vc = ChatViewController(with: model.otherUserEmail, id: model.id)
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        
        if editingStyle == .delete {
            tableView.beginUpdates()
            
            let selectedConversation = conversations[indexPath.row]
            conversations.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .left)
            
            DatabaseManager.shared.deleteConversation(conversationId: selectedConversation.id) { [weak self] success in
                if !success {
                    print("failed to delete")
                    // Add conversation back again...
                    self?.conversations.insert(selectedConversation, at: indexPath.row)
                }
            }
            
            tableView.endUpdates()
        }
    }
}

// MARK: - ProfileImageViewDelegate
extension ConversationsViewController: ProfileImageViewDelegate {
    func didTapProfileImage() {
        print("Tapped profile image ...")
    }
}
