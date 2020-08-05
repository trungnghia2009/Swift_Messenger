//
//  ChatViewController.swift
//  Messenger
//
//  Created by trungnghia on 8/2/20.
//  Copyright © 2020 trungnghia. All rights reserved.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import FirebaseAuth
import SDWebImage
import AVFoundation
import AVKit

struct Message: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
}

extension MessageKind {
    var messageKindString: String {
        switch self {
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .custom(_):
            return "custom"
        }
    }
}

struct Sender: SenderType {
    var photoURL: String
    var senderId: String
    var displayName: String
}

struct Media: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
}

class ChatViewController: MessagesViewController {
    
    // MARK: - Properties
   public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()

    
    var isNewConveration = false
    var isCamera = false
    let otherUserEmail: String
    private let conversationId: String?
    private let currentEmail = FirebaseAuth.Auth.auth().currentUser?.email
    private var messages = [Message]()
    
    private lazy var selfSender: Sender? = {
        guard let currentEmail = currentEmail else { return nil }
        
        let safeEmail = DatabaseManager.shared.safeEmail(email: currentEmail)
        return Sender(photoURL: "",
                      senderId: safeEmail, // assign to current email, match
                      displayName: "Me")
    }()
    
    // MARK: - Lifecycle
    init(with email: String, id: String?) {
        self.otherUserEmail = email
        self.conversationId = id
        super.init(nibName: nil, bundle: nil)
        
        // Call only if having conversationId
        if let conversationId = conversationId {
            listenForMessages(id: conversationId)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self // Use for interact message cell
        messageInputBar.delegate = self
        setupInputButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
    
    // MARK: - Helpers
    private func listenForMessages(id: String) {
        DatabaseManager.shared.getAllMessagesForConversation(with: id) { [weak self] (result) in
            switch result {
            case .success(let messages):
                guard !messages.isEmpty else { return }
                self?.messages = messages
                self?.messagesCollectionView.reloadDataAndKeepOffset() // scroll to latest message
            case .failure(let error):
                print("Failed to get messages, \(error)")
            }
        }
    }
    
    private func setupInputButton() {
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside { [weak self] _ in
            self?.isCamera = false
            self?.presentInputActionSheet()
        }
        
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    private func presentInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Media",
                                            message: "What would you like to attach ?",
                                            preferredStyle: .actionSheet)
        
        let photoAction = UIAlertAction(title: "Photo", style: .default) { [weak self] _ in
            self?.presentPhotoInputActionSheet()
        }
        let videoAction = UIAlertAction(title: "Video", style: .default) { [weak self] _ in
            self?.presentVideoInputActionSheet()
        }
        let audioAction = UIAlertAction(title: "Audio", style: .default) { [weak self] _ in
            self?.presentAudioInputActionSheet()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheet.addAction(photoAction)
        actionSheet.addAction(videoAction)
        actionSheet.addAction(audioAction)
        actionSheet.addAction(cancelAction)
        
        present(actionSheet, animated: true)
    }
    
    private func presentPhotoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Photo",
                                      message: "Where would you like to attach a photo from ?",
                                      preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }
        let photoLibraryAction = UIAlertAction(title: "Photo Library", style: .default) { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheet.addAction(cameraAction)
        actionSheet.addAction(photoLibraryAction)
        actionSheet.addAction(cancelAction)
        
        present(actionSheet, animated: true)
    }
    
    private func presentVideoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Video",
                                      message: "Where would you like to attach a video from ?",
                                      preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
            self?.isCamera = true
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }
        let photoLibraryAction = UIAlertAction(title: "Library", style: .default) { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheet.addAction(cameraAction)
        actionSheet.addAction(photoLibraryAction)
        actionSheet.addAction(cancelAction)
        
        present(actionSheet, animated: true)
    }
    
    private func presentAudioInputActionSheet() {
        print("Handle audio..")
    }

}


// MARK: - InputBarAccessoryViewDelegate
extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
            let selfSender = self.selfSender,
            let messageId = createMessageId() else { return }
        
        print("Sending: \(text)")
        
        let message = Message(sender: selfSender,
                              messageId: messageId,
                              sentDate: Date(),
                              kind: .text(text))
        
        // Send message
        if isNewConveration {
            // create conversation in database
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, name: self.title ?? "User", firstMessage: message) { [weak self] (success) in
                if success {
                    print("Message send")
                    self?.isNewConveration = false // Do not create conversation once was created
                } else {
                    print("Failed to send")
                }
            }
        } else {
            // append to existing conversation data
            guard let conversationId = conversationId,
                let name = self.title else { return }
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: otherUserEmail, name: name, newMessage: message) { (success) in
                if success {
                    print("Message send")
                } else {
                    print("Failed to send")
                }
            }
            
        }
    }
    
    private func createMessageId() -> String? {
        // date, otherUserEmail, senderEmail, randomInt
        guard var currentEmail = currentEmail else { return nil}
        currentEmail = DatabaseManager.shared.safeEmail(email: currentEmail)
        let dateString = Self.dateFormatter.string(from: Date())
        
        let newIdentifier = "\(otherUserEmail)_\(currentEmail)_\(dateString)"
        print("Created message id: \(newIdentifier)")
        return newIdentifier
    }
}


// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let messageId = createMessageId(),
            let conversationId = conversationId,
            let name = self.title,
            let selfSender = selfSender else { return }
        
        let fileName = "photo_message_\(messageId)"
        
        if let selectedImage = info[.editedImage] as? UIImage,
            let imageData = selectedImage.resizeWithWidth(width: 800)?.jpegData(compressionQuality: 0.8) {
            // Handle Photo
            StorageManager.shared.uploadMessagePhoto(with: imageData, fileName: fileName) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let urlString):
                    print("Url for photo message: \(urlString)")
                    
                    guard let url = URL(string: urlString),
                        let placeholder = UIImage(systemName: "questionmark.diamond") else { return }
                    
                    let media = Media(url: url,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: .zero)
                    
                    let message = Message(sender: selfSender,
                                          messageId: messageId,
                                          sentDate: Date(),
                                          kind: .photo(media))
                    
                    // Send Photo message
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: self.otherUserEmail, name: name, newMessage: message) { success in
                        if success {
                            print("Sent photo message")
                        } else {
                            print("Failed to send photo message")
                        }
                    }
                case .failure(let error):
                    print("Failed to upload message photo, \(error)")
                }
            }
            
        } else if let videoUrl = info[.mediaURL] as? URL {
            print("Handle upload video")
            
            var safeUrl: URL?
            
            // Handle for using camera or not
            if !isCamera {
                do {
                    if #available(iOS 13, *) {
                        // If iOS13 slice the URL to get the name of the file
                        let urlString = videoUrl.relativeString
                        print(urlString)
                        let urlSlices = urlString.split(separator: ".")
                        // Create a temp directory using the file name
                        let tempDirectionURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                        let targetURL = tempDirectionURL.appendingPathComponent(String(urlSlices[1])).appendingPathExtension(String(urlSlices[2]))
                        
                        //Copy the video over
                        try FileManager.default.copyItem(at: videoUrl, to: targetURL)
                        safeUrl = targetURL
                    } else {
                        safeUrl = videoUrl
                    }
                } catch let error {
                    print(error.localizedDescription)
                    return
                }
            } else {
                safeUrl = videoUrl
            }
            
            
            guard let url = safeUrl else { return }
            print(url.absoluteString)
            
            // Handle and upload video
            let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".mov"
            StorageManager.shared.uploadMessageVideo(with: url, fileName: fileName) { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success(let urlString):
                    print("Url for video message: \(urlString)")

                    guard let url = URL(string: urlString),
                        let placeholder = UIImage(systemName: "plus") else { return }

                    let media = Media(url: url,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: .zero)

                    let message = Message(sender: selfSender,
                                          messageId: messageId,
                                          sentDate: Date(),
                                          kind: .video(media))

                    // Send Photo message
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: self.otherUserEmail, name: name, newMessage: message) { success in
                        if success {
                            print("Sent video message")
                        } else {
                            print("Failed to send video message")
                        }
                    }
                case .failure(let error):
                    print("Failed to upload message photo, \(error)")
                }
            }
        }
        
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: - MessageKit
extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }
        
        fatalError("Self Sender is nil, email should be cached")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    // Display image
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else { return }
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else { return }
            imageView.sd_setImage(with: imageUrl)
        default:
            break
        }
    }
}

// MARK: - MessageCellDelegate - MessageKit
extension ChatViewController: MessageCellDelegate {
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        
        let selectedMessage = messages[indexPath.section]
        
        switch selectedMessage.kind {
        case .photo(let media):
            print("Photo touched")
            guard let imageUrl = media.url else { return }
            let vc = UINavigationController(rootViewController: PhotoViewerViewController(with: imageUrl))
            vc.title = "Photo"
            vc.modalPresentationStyle = .fullScreen
            vc.modalTransitionStyle = .crossDissolve
            present(vc, animated: true)
        case .video(let media):
            guard let videoUrl = media.url else { return }
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: videoUrl)
            present(vc, animated: true) {
                vc.player?.play()
            }
        default:
            break
        }
    }
    
}
