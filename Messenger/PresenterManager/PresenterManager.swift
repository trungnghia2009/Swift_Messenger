//
//  PresenterManager.swift
//  Messenger
//
//  Created by trungnghia on 8/6/20.
//  Copyright © 2020 trungnghia. All rights reserved.
//

import UIKit

class PresenterManager {
    
    static let shared = PresenterManager()
    
    private init() {}
    
    enum VC {
        case tabBarController
        case loginController
    }
    
    func show(vc: VC) {
        
        var viewController: UIViewController
        
        switch vc {
        case .tabBarController:
            viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "tabBarController")
        case .loginController:
            viewController = UINavigationController(rootViewController: LoginViewController())
        }
        
        if let sceneDelegate =  UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate, let window = sceneDelegate.window  {
            window.rootViewController = viewController
            
            UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve, animations: nil, completion: nil)
        }
        
    }

    
}
