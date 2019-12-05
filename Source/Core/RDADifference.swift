//
//  RDADifference.swift
//  RXCDiffArray
//
//  Created by ruixingchen on 10/30/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import Foundation

public struct RDADifference<Element> {

    //should we store the object change:
//    public struct ElementChange {
//        var previous:ElementContainer.Element?
//        var current:ElementContainer.Element?
//    }

    public enum Change {
        case sectionInsert(offset:Int)
        case sectionRemove(offset:Int)
        case sectionUpdate(offset:Int)
        case sectionMove(fromOffset:Int, toOffset:Int)

        case elementInsert(offset:Int, section:Int)
        case elementRemove(offset:Int, section:Int)
        case elementUpdate(offset:Int, section:Int)
        case elementMove(fromOffset:Int,fromSection:Int, toOffset:Int,toSection:Int)
    }

    ///if this is not nil, should replace the dataSource with this to avoid crash
    public var dataAfterChange:[Element]?

    ///all the changes
    public var changes:[Change] = []

    init<C: Collection>(changes:C) where C.Element == Change {
        self.changes = [Change].init(changes)
    }

}

extension RDADifference: CustomStringConvertible {

    public var description: String {
        var changeDescriptions:[String] = []
        for i in changes {
            changeDescriptions.append(String.init(describing: i))
        }
        return changeDescriptions.joined(separator: "\n")
    }
    
}
