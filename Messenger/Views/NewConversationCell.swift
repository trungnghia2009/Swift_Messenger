//
//  NewConversationCell.swift
//  Messenger
//
//  Created by trungnghia on 8/5/20.
//  Copyright © 2020 trungnghia. All rights reserved.
//

import UIKit
import SDWebImage

class NewConversationCell: UITableViewCell {
    
    // MARK: - Properties
    static let reuseIdentifier = String(describing: NewConversationCell.self)
    
    private let userImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 25
        iv.layer.masksToBounds = true
        return iv
    }()
    
    private let userNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 21, weight: .medium)
        return label
    }()
    
    
    // MARK: - Lifecycle
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        userImageView.frame = CGRect(x: 10,
                                     y: 10,
                                     width: 50,
                                     height: 50)
        
        userNameLabel.frame = CGRect(x: userImageView.right + 10,
                                     y: 10,
                                     width: contentView.width - 20 - userImageView.width,
                                     height: 50)
        
    }
    
    // MARK: - Helpers
    func configure(with model: SearchResult) {
        userNameLabel.text = model.name
        
        let path = "images/\(model.email)_profile_picture.png"
        StorageManager.shared.downloadURL(for: path) { [weak self] (result) in
            switch result {
            case .success(let url):
                self?.userImageView.sd_setImage(with: url)
            case .failure(let error):
                print("Failed to get profile image, \(error)")
            }
        }
    }
    
}
