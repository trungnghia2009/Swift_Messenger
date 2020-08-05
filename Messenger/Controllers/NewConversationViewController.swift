//
//  NewConversationViewController.swift
//  Messenger
//
//  Created by trungnghia on 7/31/20.
//  Copyright © 2020 trungnghia. All rights reserved.
//

import UIKit
import JGProgressHUD
import FirebaseAuth

struct SearchResult {
    let name: String
    let email: String
}

private let reuseIdentifier = "New Conversation Cell"

class NewConversationViewController: UIViewController {

    // MARK: - Properties
    private var users = [[String: String]]()
    private var results = [SearchResult]()
    private var hasFetched = false
    
    private let spinner = JGProgressHUD(style: .dark)
    private let searchBar = UISearchBar()
    private let tableView = UITableView()
    
    var completion: ((SearchResult) -> Void)?  //Use closure for callBack
    
    private let noResultLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.text = "No Results"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        return label
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        configureNavigationBar()
        configureUI()
        configureSearchBar()
        configureTableView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.frame = view.bounds
        noResultLabel.frame = CGRect(x: view.width / 4,
                                     y: (view.height - 200) / 2,
                                     width: view.width / 2,
                                     height: 200)
        
    }
    
    
    // MARK: - Helpers
    private func configureNavigationBar() {
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(didTapCancel))
    }
    
    private func configureUI() {
        view.addSubview(tableView)
        view.addSubview(noResultLabel)
    }
    
    private func configureSearchBar() {
        searchBar.delegate = self
        searchBar.placeholder = "Search for Users..."
        searchBar.becomeFirstResponder()
    }
    
    private func configureTableView() {
        tableView.isHidden = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(NewConversationCell.self, forCellReuseIdentifier: NewConversationCell.reuseIdentifier)
    }
    
    // MARK: - Selectors
    @objc private func didTapCancel() {
        dismiss(animated: true)
    }

}


// MARK: - UISearchBarDelegate
extension NewConversationViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        
        searchBar.resignFirstResponder()
        results.removeAll()
        spinner.show(in: view)
        searchUsers(query: text)
    }
    
    func searchUsers(query: String) {
        // check if array has firebase result
        if hasFetched {
            // if it does: filter
            filterUsers(with: query)
        } else {
            // if not, fetch then filter
            DatabaseManager.shared.getAllUsers { [weak self] (result) in
                self?.hasFetched = true
                
                switch result {
                case .success(let usersCollection):
                    self?.users = usersCollection
                    self?.filterUsers(with: query)
                case .failure(let error):
                    print("Failed to get users, \(error.localizedDescription)")
                }
            }
        }
    }
    
    func filterUsers(with term: String) {
        spinner.dismiss()
        guard let currentUserEmail = FirebaseAuth.Auth.auth().currentUser?.email,
            hasFetched else { return }
        let safeEmail = DatabaseManager.shared.safeEmail(email: currentUserEmail)
        
        let results: [SearchResult] = users.filter({
            // Do not show current user
            guard let email = $0["email"], email != safeEmail else { return false }
            
            // Get search keyword
            guard var name = $0["name"]?.lowercased() else { return false }
            
            name = name.forSorting
            return name.localizedCaseInsensitiveContains(term)
        }).compactMap({
            guard let email = $0["email"],
                let name = $0["name"] else { return nil}
            return SearchResult(name: name, email: email)
        })
        
        self.results = results
        updateUI()
    }
    
    func updateUI() {
        if results.isEmpty {
            noResultLabel.isHidden = false
            tableView.isHidden = true
        } else {
            noResultLabel.isHidden = true
            tableView.isHidden = false
            tableView.reloadData()
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension NewConversationViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = results[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: NewConversationCell.reuseIdentifier, for: indexPath) as! NewConversationCell
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // start conversation
        let targetUserData = results[indexPath.row]
        dismiss(animated: true) { [weak self] in
            self?.completion?(targetUserData)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}
