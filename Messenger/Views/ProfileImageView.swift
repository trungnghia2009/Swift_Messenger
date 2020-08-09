//
//  ProfileImageView.swift
//  Messenger
//
//  Created by trungnghia on 8/8/20.
//  Copyright © 2020 trungnghia. All rights reserved.
//

import UIKit

protocol ProfileImageViewDelegate: class {
    func didTapProfileImage()
}

class ProfileImageView: UIImageView {
    
    // MARK: - Properties
    weak var delegate: ProfileImageViewDelegate?
    var url: URL? {
        didSet {
            configure()
        }
    }
    
    // MARK: - Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        setDimensions(width: 30, height: 30)
        layer.cornerRadius = 15
        clipsToBounds = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleProfileImageTappped))
        addGestureRecognizer(tap)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Helpers
    private func configure() {
        guard let url = url else { return }
        sd_setImage(with: url)
    }
    
    //MARK: - Selectors
    @objc private func handleProfileImageTappped() {
        delegate?.didTapProfileImage()
    }
    
}
