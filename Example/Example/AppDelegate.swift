//
//  AppDelegate.swift
//  Example
//
//  Created by ruixingchen on 10/30/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let data = RXCDiffArray<[Int]>()
        let diff = data.batchWithDifferenceKit_1D(section: 2) {
            data.add(0)
            data.add(1)
        }
        print(diff)
        return true
    }


}

