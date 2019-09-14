//
//  AppDelegate.swift
//  RXCDiffArrayExample
//
//  Created by ruixingchen on 9/6/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let vc = ViewController()
        let nav = UINavigationController(rootViewController: vc)

        self.window = UIWindow()
        self.window?.rootViewController = nav
        self.window?.makeKeyAndVisible()

        return true
    }

}

