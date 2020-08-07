//
//  Profile.swift
//  Messenger
//
//  Created by trungnghia on 8/7/20.
//  Copyright © 2020 trungnghia. All rights reserved.
//

import Foundation

enum ProfileViewModelType {
    case info
    case logout
}

struct ProfileViewModel {
    let viewModelType: ProfileViewModelType
    let title: String
    let handler: (() -> Void)?
}
