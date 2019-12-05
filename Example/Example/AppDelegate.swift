//
//  AppDelegate.swift
//  Example
//
//  Created by ruixingchen on 10/30/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import UIKit

extension String : RDADiffableRowElementProtocol {
    public var rda_diffIdentifier: AnyHashable {return self}
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        return true
    }

}

