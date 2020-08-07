//
//  TabBarController.swift
//  Messenger
//
//  Created by trungnghia on 8/6/20.
//  Copyright © 2020 trungnghia. All rights reserved.
//

import UIKit

final class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setTabBarItems()
    }
    
    func setTabBarItems() {
        let myTabBarItem1 = (tabBar.items?[0])! as UITabBarItem
        myTabBarItem1.image = UIImage(systemName: "message")
        myTabBarItem1.selectedImage = UIImage(systemName: "message.fill")
        myTabBarItem1.title = "Chats"
        
        let myTabBarItem2 = (tabBar.items?[1])! as UITabBarItem
        myTabBarItem2.image = UIImage(systemName: "person")
        myTabBarItem2.selectedImage = UIImage(systemName: "person.fill")
        myTabBarItem2.title = "Profile"
    }

}

extension TabBarController {
    
    //Add tabBar bounce effect
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let barItemView = item.value(forKey: "view") as? UIView else { return }
        
        let timeInterval: TimeInterval = 0.3
        let propertyAnimator = UIViewPropertyAnimator(duration: timeInterval, dampingRatio: 0.5) {
            barItemView.transform = CGAffineTransform.identity.scaledBy(x: 1.25, y: 1.25)
        }
        propertyAnimator.addAnimations({ barItemView.transform = .identity }, delayFactor: CGFloat(timeInterval))
        propertyAnimator.startAnimation()
    }
}
