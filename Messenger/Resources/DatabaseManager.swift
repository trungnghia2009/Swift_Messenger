//
//  DatabaseManager.swift
//  Messenger
//
//  Created by trungnghia on 8/1/20.
//  Copyright © 2020 trungnghia. All rights reserved.
//

import Foundation
import FirebaseDatabase

struct ChatAppUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
    
    var safeEmail: String {
        let safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
                                    .replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}

final class DatabaseManager {
    static let shared = DatabaseManager()
    private let database = Database.database().reference()
    
}


// MARK: - Account Management
extension DatabaseManager {
    
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void)) {
        
        let safeEmail = email.replacingOccurrences(of: ".", with: "-")
                             .replacingOccurrences(of: "@", with: "-")

        database.child(safeEmail).observeSingleEvent(of: .value) { (snapshot) in
            if let value = snapshot.value as? NSDictionary, let _ = value["first_name"] {
                completion(true)
                return
            }
            
            completion(false)

        }
    }
    
    /// Insert new user to database
    public func insertUser(with user: ChatAppUser) {
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName,
        ])
    }
}

