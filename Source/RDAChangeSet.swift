
//  RXCDiffArrayExample
//
//  Created by ruixingchen on 9/9/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import Foundation

public struct RDAChangeSet<T> {

    static func empty()->RDAChangeSet {
        return RDAChangeSet(changes: [])
    }

    public enum Change {
        case sectionInsert(SectionInsert)
        case sectionDelete(SectionDelete)
        case sectionUpdate(SectionUpdate)
        case sectionMove(SectionMove)
        case elementInsert(ElementInsert)
        case elementDelete(ElementDelete)
        case elementUpdate(ElementUpdate)
        case elementMove(ElementMove)
    }

    public struct SectionInsert {
        public let item: T
        public let index: Int
    }

    public struct SectionDelete {
        public let item: T
        public let index: Int
    }

    public struct SectionUpdate {
        public let oldItem: T
        public let newItem: T
        public let index: Int
    }

    public struct SectionMove {
        public let item: T
        public let fromIndex: Int
        public let toIndex: Int
    }

    public struct ElementInsert {
        public let item: T
        public let index: Int
        public let section:Int
    }

    public struct ElementDelete {
        public let item: T
        public let index: Int
        public let section:Int
    }

    public struct ElementUpdate {
        public let oldItem: T
        public let newItem: T
        public let index: Int
        public let section:Int
    }

    ///支持跨Section移动元素
    public struct ElementMove {
        public let item: T
        public let fromIndex: Int
        public let fromSection:Int
        public let toIndex: Int
        public let toSection:Int
    }

    let changes:[Change]

    var isEmpty:Bool {return self.changes.isEmpty}

}
