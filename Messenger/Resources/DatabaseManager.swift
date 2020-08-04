//
//  DatabaseManager.swift
//  Messenger
//
//  Created by trungnghia on 8/1/20.
//  Copyright © 2020 trungnghia. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth

struct UploadMessage {
    let id: String
    let type: String
    let content: String
    let date: String
    let senderEmail: String
    let name: String
}

struct ChatAppUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
    
    var safeEmail: String {
        let safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
            .replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    var profilePictureFileName: String {
        //nghia-gmail-com_profile_picture.png
        return "\(safeEmail)_profile_picture.png"
    }
}

final class DatabaseManager {
    static let shared = DatabaseManager()
    private init() {}
    private let database = Database.database().reference()
    private let currentEmail = FirebaseAuth.Auth.auth().currentUser?.email
    
    func safeEmail(email: String) -> String {
        let safeEmail = email.replacingOccurrences(of: ".", with: "-")
            .replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
}


// MARK: - Account Management
extension DatabaseManager {
    
    public enum DatabaseError: Error {
        case failedToFetch
    }
    
    
    /// Check user if exists
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
    public func insertUser(with user: ChatAppUser, completion: @escaping((Bool) -> Void) ) {
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName,
            ], withCompletionBlock: { (error, _) in
                guard error == nil else {
                    print("Failed to write to database")
                    completion(false)
                    return
                }
                
                // upload data to users, if not existing add new
                self.database.child("users").observeSingleEvent(of: .value) { (snapshot) in
                    if var usersCollection = snapshot.value as? [[String: String]] {
                        // append to user dictionary
                        let newElement = [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                        usersCollection.append(newElement)
                        
                        self.database.child("users").setValue(usersCollection, withCompletionBlock: { (error, _) in
                            guard error == nil else {
                                completion(false)
                                return
                            }
                            completion(true)
                        })
                    } else {
                        // create that array
                        let newCollection: [[String: String]] = [
                            [
                                "name": user.firstName + " " + user.lastName,
                                "email": user.safeEmail
                            ]
                        ]
                        self.database.child("users").setValue(newCollection, withCompletionBlock: { (error, _) in
                            guard error == nil else {
                                completion(false)
                                return
                            }
                            completion(true)
                        })
                    }
                }
                
                
        })
    }
    
    /// Get all users from database
    public func getAllUsers(completion: @escaping ((Result<[[String: String]], Error>)-> Void)) {
        database.child("users").observeSingleEvent(of: .value) { (snapshot) in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            completion(.success(value))
        }
    }
    
    /// Get user info -> Use for get current user name
    public func getDataFor(path: String, completion: @escaping (Result<Any, Error>) -> Void) {
        database.child("\(path)").observeSingleEvent(of: .value) { (snapshot) in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
    
}

// MARK: - Sending messages / conversation
extension DatabaseManager {
    
    /*
     "conversationID" {
        "message": [
            {
                "id": String
                "type": text, photo, video
                "content": String, image, video
                "date": Date()
                "sender_email": String
                "is_read": true/false
            }
     
        ]
     
     }
     
     ---> inside safeEmail
     conversations => [
         [
            "id": "conversationID"
            "other_user_email":
            "name":
            "latest_message": => {
                "date": Date()
                "latest_message": "message"
                "is_read": true/false
            }
         ],
     ]
     
     */
    
    /// Creates a new conversation with target user email and first message sent
    public func createNewConversation(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping ((Bool) -> Void)) {
        guard let currentEmail = currentEmail,
            let currentName = UserDefaults.standard.value(forKey: "name") as? String
        else { return }
        
        let safeEmail = DatabaseManager.shared.safeEmail(email: currentEmail)
        
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value) { [weak self] (snapshot) in
            guard let self = self else { return }
            
            guard var userNode = snapshot.value as? [String: Any] else {
                completion(false)
                print("User not found...")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            let conversationId = "conversation_\(firstMessage.messageId)"
            var message = ""
            
            switch firstMessage.kind {
                
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .custom(_):
                break
            }
            
            let newConversationData: [String: Any] = [
                "id": conversationId,
                "other_user_email": otherUserEmail,
                "name": name,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            let recipient_newConversationData: [String: Any] = [
                "id": conversationId,
                "other_user_email": safeEmail,
                "name": currentName,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            // Update recipient conversation entry
            self.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { (snapshot) in
                if var conversations = snapshot.value as? [[String: Any]] {
                    // append
                    conversations.append(recipient_newConversationData)
                    self.database.child("\(otherUserEmail)/conversations").setValue(conversations)
                } else {
                    // create
                    self.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversationData])
                }
            }
            
            
            // Update current user conversation entry
            let uploadMessage = UploadMessage(id: firstMessage.messageId,
                                              type: firstMessage.kind.messageKindString,
                                              content: message,
                                              date: dateString,
                                              senderEmail: safeEmail,
                                              name: name)

            
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                // Conversation array exists for current user
                // You should append
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                
                ref.setValue(userNode) { [weak self] (error, _) in
                    if let error = error {
                        print(error.localizedDescription)
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(conversationId: conversationId,
                                                     uploadMessage: uploadMessage,
                                                     completion: completion)
                }
            } else {
                // Create new conversation
                userNode["conversations"] = [newConversationData]
                
                ref.setValue(userNode) { [weak self] (error, _) in
                    if let error = error {
                        print(error.localizedDescription)
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(conversationId: conversationId,
                                                     uploadMessage: uploadMessage,
                                                     completion: completion)
                }
            }
        }
    }
    
    
    private func finishCreatingConversation(conversationId: String, uploadMessage: UploadMessage, completion: @escaping (Bool) -> Void) {
        
        let message: [String: Any] = [
            "id": uploadMessage.id,
            "type": uploadMessage.type,
            "content": uploadMessage.content,
            "date": uploadMessage.date,
            "sender_email": uploadMessage.senderEmail,
            "name": uploadMessage.name,
            "is_read": false
        ]
        
        let value: [String: Any] = [
            "messages": [
                message
            ]
        ]
        
        // Create new conversation separately
        database.child("\(conversationId)").setValue(value) { (error, _) in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    /// Fetches and returns all conversations for the user with passed in email
    func getAllConversations(for email: String, completion: @escaping ((Result<[Conversation], Error>) -> Void)) {
        database.child("\(email)/conversations").observe(.value) { (snapshot) in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let conversations: [Conversation] = value.compactMap({ dictionary in
                guard let conversationId = dictionary["id"] as? String,
                    let name = dictionary["name"] as? String,
                    let otherUserEmail = dictionary["other_user_email"] as? String,
                    let latestMessage = dictionary["latest_message"] as? [String: Any],
                    let date = latestMessage["date"] as? String,
                    let isRead = latestMessage["is_read"] as? Bool,
                    let message = latestMessage["message"] as? String
                else { return nil}
                
                let latestMessageObject = LatestMessage(date: date,
                                                        text: message,
                                                        isRead: isRead)
                
                return Conversation(id: conversationId,
                                    name: name,
                                    otherUserEmail: otherUserEmail,
                                    latestMessage: latestMessageObject)
            })
            
            completion(.success(conversations))
            
        }
    }
    
    /// Gets all messages for a given conversation
    func getAllMessagesForConversation(with id: String, completion: @escaping ((Result<[Message], Error>) -> Void)) {
        database.child("\(id)/messages").observe(.value) { (snapshot) in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let messages: [Message] = value.compactMap({ dictionary in
                guard let name = dictionary["name"] as? String,
                    let isRead = dictionary["is_read"] as? Bool,
                    let messageId = dictionary["id"] as? String,
                    let content = dictionary["content"] as? String,
                    let dateString = dictionary["date"] as? String,
                    let date = ChatViewController.dateFormatter.date(from: dateString),
                    let senderEmail = dictionary["sender_email"] as? String,
                    let type = dictionary["type"]
                else { return nil}
                
                let sender = Sender(photoURL: "",
                                    senderId: senderEmail,
                                    displayName: name)
                
                return Message(sender: sender,
                               messageId: messageId,
                               sentDate: date,
                               kind: .text(content))
                
            })
            
            completion(.success(messages))
            
        }
    }
    
    /// Sends a message with target conversation and message
    func sendMessage(to conversationId: String, otherUserEmail: String, name: String, newMessage: Message, completion: @escaping ((Bool) -> Void)) {
        
        // append messge to target conversation
        database.child("\(conversationId)/messages").observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self else { return }
            
            guard var currentMessages = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            
            guard let currentEmail = self.currentEmail else { return }
            let safeEmail = DatabaseManager.shared.safeEmail(email: currentEmail)
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            var message = ""
            
            switch newMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .custom(_):
                break
            }
            
            let newMessageEntry: [String: Any] = [
                "id": newMessage.messageId,
                "type": newMessage.kind.messageKindString,
                "content": message,
                "date": dateString,
                "sender_email": safeEmail,
                "name": name,
                "is_read": false
            ]
            
            currentMessages.append(newMessageEntry)
            
            // update message to conversation
            self.database.child("\(conversationId)/messages").setValue(currentMessages) { (error, _) in
                guard error == nil else {
                    completion(false)
                    return
                }
                
                // update sender latest message
                self.database.child("\(safeEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
                    guard var currentUserConversations = snapshot.value as? [[String: Any]] else {
                        completion(false)
                        return
                    }
                    
                    // Find target conversation and then update
                    for (index, conversation) in currentUserConversations.enumerated() {
                        if let currentId = conversation["id"] as? String, currentId == conversationId {
                            print("Find out the value....")
                            let updatedValue: [String: Any] = [
                                "date": dateString,
                                "message": message,
                                "is_read": false
                            ]
                            currentUserConversations[index]["latest_message"] = updatedValue
                            break
                        }
                    }
                    
                    // update to sender
                    self.database.child("\(safeEmail)/conversations").setValue(currentUserConversations) { (error, _) in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        // update recipent latest message--------------------------
                        self.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
                            guard var currentUserConversations = snapshot.value as? [[String: Any]] else {
                                completion(false)
                                return
                            }
                            
                            // Find target conversation and then update
                            for (index, conversation) in currentUserConversations.enumerated() {
                                if let currentId = conversation["id"] as? String, currentId == conversationId {
                                    print("Find out the value....")
                                    let updatedValue: [String: Any] = [
                                        "date": dateString,
                                        "message": message,
                                        "is_read": false
                                    ]
                                    currentUserConversations[index]["latest_message"] = updatedValue
                                    break
                                }
                            }
                            
                            // update to recipent
                            self.database.child("\(otherUserEmail)/conversations").setValue(currentUserConversations) { (error, _) in
                                guard error == nil else {
                                    completion(false)
                                    return
                                }
                                completion(true)
                            }
                            
                        }

                    }

                }
                
            }
        }
    }
}
