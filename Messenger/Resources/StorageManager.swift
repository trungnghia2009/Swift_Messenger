//
//  StorageManager.swift
//  Messenger
//
//  Created by trungnghia on 8/2/20.
//  Copyright © 2020 trungnghia. All rights reserved.
//

import Foundation
import FirebaseStorage

typealias UploadFileCompletion = (Result<String, Error>) -> Void

/// Allow you to get, fetch, upload files to firebase storage
final class StorageManager {
    
    enum StorageErrors: Error{
        case failedToUpload
        case failedToGetUrl
        case errorDetail(Error)
    }
    
    static let shared = StorageManager()
    private init() {}
    private let storage = Storage.storage().reference()
    
    /*
     fileName: /image/nghia-gmail-com_profile_picture.png
     */
    
    /// Uploads picture to firebase and returns completion with url string to download
    public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping UploadFileCompletion) {
        
        storage.child("images/\(fileName)").putData(data, metadata: nil) { [weak self] (metaData, error) in
            guard let self = self else { return }
            
            guard error == nil else {
                print("Failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self.storage.child("images/\(fileName)").downloadURL { (url, error) in
                if let error = error {
                    print("Failed to get url from firebase for picture, \(error.localizedDescription)")
                    completion(.failure(StorageErrors.failedToGetUrl))
                    return
                }
                
                guard let url = url else {
                    print("Failed to get url")
                    completion(.failure(StorageErrors.failedToGetUrl))
                    return
                }
                
                let urlString = url.absoluteString
                print("Download url returned: \(urlString)")
                completion(.success(urlString))
            }
        }
    }
    
    /// Download picture from Url
    public func downloadURL(for path: String, completion: @escaping ((Result<URL, Error>) -> Void)) {
        let reference = storage.child(path)
        
        reference.downloadURL { (url, error) in
            if let error = error {
                completion(.failure(StorageErrors.errorDetail(error)))
                return
            }
            
            guard let url = url else {
                completion(.failure(StorageErrors.failedToGetUrl))
                return
            }
            
            completion(.success(url))
        }
    }
    
    /// Upload image that will be sent in a conversation message
    public func uploadMessagePhoto(with data: Data, fileName: String, completion: @escaping UploadFileCompletion) {
        
        storage.child("message_images/\(fileName)").putData(data, metadata: nil) { [weak self] (metaData, error) in
            guard let self = self else { return }
            
            guard error == nil else {
                print("Failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self.storage.child("message_images/\(fileName)").downloadURL { (url, error) in
                if let error = error {
                    print("Failed to get url from firebase for picture, \(error.localizedDescription)")
                    completion(.failure(StorageErrors.failedToGetUrl))
                    return
                }
                
                guard let url = url else {
                    print("Failed to get url")
                    completion(.failure(StorageErrors.failedToGetUrl))
                    return
                }
                
                let urlString = url.absoluteString
                print("Download url returned: \(urlString)")
                completion(.success(urlString))
            }
        }
    }
    
    /// Upload video that will be sent in a conversation message
    public func uploadMessageVideo(with fileUrl: URL, fileName: String, completion: @escaping UploadFileCompletion) {
        
        storage.child("message_videos/\(fileName)").putFile(from: fileUrl, metadata: nil) { [weak self] (metaData, error) in
            guard let self = self else { return }
            
            guard error == nil else {
                print("Failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self.storage.child("message_videos/\(fileName)").downloadURL { (url, error) in
                if let error = error {
                    print("Failed to get url from firebase for picture, \(error.localizedDescription)")
                    completion(.failure(StorageErrors.failedToGetUrl))
                    return
                }
                
                guard let url = url else {
                    print("Failed to get url")
                    completion(.failure(StorageErrors.failedToGetUrl))
                    return
                }
                
                let urlString = url.absoluteString
                print("Download url returned: \(urlString)")
                completion(.success(urlString))
            }
        }
    }
}
