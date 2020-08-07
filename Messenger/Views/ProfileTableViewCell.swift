//
//  ProfileTableViewCell.swift
//  Messenger
//
//  Created by trungnghia on 8/7/20.
//  Copyright © 2020 trungnghia. All rights reserved.
//

import UIKit

class ProfileTableViewCell: UITableViewCell {

    static let reuseIdentifier = String(describing: ProfileTableViewCell.self)
    
    func setup(with viewModel: ProfileViewModel) {
        textLabel?.text = viewModel.title
        
        switch viewModel.viewModelType {
        case .info:
            textLabel?.textAlignment = .left
            selectionStyle = .none
        case .logout:
            textLabel?.textColor = .red
            textLabel?.textAlignment = .center
        }
    }
    
}
