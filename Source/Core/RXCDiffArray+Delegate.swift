//
//  RXCDiffArray+Delegate.swift
//  RXCDiffArray
//
//  Created by ruixingchen on 12/3/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import Foundation

extension RXCDiffArray {

    public func addDelegate(_ delegate:RXCDiffArrayDelegate) {
        self.safeWriteExecute(userInfo: nil) {
            guard !self.delegates.contains(delegate as AnyObject) else {return}
            self.delegates.add(delegate)
        }
    }

    public func removeDelegate(_ delegate:RXCDiffArrayDelegate) {
        self.safeWriteExecute(userInfo: nil) {
            self.delegates.remove(delegate)
        }
    }

    internal func notifyDelegate(diff:[Difference], userInfo:[AnyHashable:Any]?) {
        if (userInfo?[RXCDiffArrayKey.notify] as? Bool ?? true) {
            rdalog("开始通知代理")
            self.safeWriteExecute(userInfo: userInfo) {
                let _allDelegates = self.delegates.allObjects
                DispatchQueue.main.async {
                    //通知要确保在主线程进行
                    for i in _allDelegates {
                        if let delegate = i as? RXCDiffArrayDelegate {
                            delegate.diffArray(diffArray: self, didModifiedWith: diff)
                        }
                    }
                }
            }
        }
    }

}
