
//  RXCDiffArrayExample
//
//  Created by ruixingchen on 9/9/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import Foundation
#if canImport(DifferenceKit)
import DifferenceKit
#endif

///两个集合之间的差异, 根据Swift的CollectionDifference改的, 支持二维数据和更多的改变类型
public struct RDADifference<SectionElement, RowElement>  {

    public static func empty()->RDADifference {
        return RDADifference(changes: Array<Change>())
    }

    public enum Change {
        case sectionInsert(offset:Int, element:SectionElement?)
        case sectionRemove(offset:Int, element:SectionElement?)
        case sectionUpdate(offset:Int, oldElement:SectionElement?, newElement:SectionElement?)
        case sectionMove(fromOffset:Int, toOffset:Int, element:SectionElement?)

        case elementInsert(offset:Int, section:Int, element:RowElement?)
        case elementRemove(offset:Int, section:Int, element:RowElement?)
        case elementUpdate(offset:Int, section:Int, oldElement:RowElement?, newElement:RowElement?)
        case elementMove(fromOffset:Int,fromSection:Int, toOffset:Int,toSection:Int, element:RowElement?)

        public var offset:Int {
            switch self {
            case .sectionRemove(offset: let o, element: _):
                return o
            case .sectionInsert(offset: let o, element: _):
                return o
            case .sectionUpdate(offset: let o, oldElement: _, newElement: _):
                return o
            case .sectionMove(fromOffset: let o, toOffset: _, element: _):
                return o
            case .elementRemove(offset: let o, section: _, element: _):
                return o
            case .elementInsert(offset: let o, section: _, element: _):
                return o
            case .elementUpdate(offset: let o, section: _, oldElement: _, newElement: _):
                return o
            case .elementMove(fromOffset: let o, fromSection: _, toOffset: _, toSection: _, element: _):
                return o
            }
        }

    }

    ///当使用DifferenceKit计算差异的时候, 会有一个每一步的中间状态, 这个状态需要在更新UI的时候被同步到数据源中, 如果这个值不为nil, 那么应该重新设置数据源, 以防止数据源和UI不同步而崩溃
    public var dk_finalDataForCurrentStep:ContiguousArray<SectionElement>?

    ///已经完全排序好的所有Change, 主要用于遍历
    public let allChanges:[Change]

    ///from lower offset to larger offset
    public let sectionRemoved:[Change]

    ///from lower offset to larger offset
    public let sectionInserted:[Change]

    ///from lower offset to larger offset
    public let sectionUpdated:[Change]

    ///from lower offset to larger offset
    public let sectionMoved:[Change]

    ///from lower offset to larger offset
    public let elementRemoved:[Change]

    ///from lower offset to larger offset
    public let elementInserted:[Change]

    ///from lower offset to larger offset
    public let elementUpdated:[Change]

    ///from lower offset to larger offset
    public let elementMoved:[Change]

    /// 注意: 手动随意初始化的Change记录可能会导致更新UI的时候崩溃, 要根据真实的数据变化顺序传入changes
    public init<C:Collection>(changes:C, sorted:Bool=false) where C.Element == Change {

        var __sectionRemoved:[Change] = []
        var __sectionInserted:[Change] = []
        var __sectionUpdated:[Change] = []
        var __sectionMoved:[Change] = []
        var __elementRemoved:[Change] = []
        var __elementInserted:[Change] = []
        var __elementUpdated:[Change] = []
        var __elementMoved:[Change] = []

        for i in changes {
            switch i {
            case .sectionRemove(offset: _, element: _):
                __sectionRemoved.append(i)
            case .sectionInsert(offset: _, element: _):
                __sectionInserted.append(i)
            case .sectionUpdate(offset: _, oldElement: _, newElement: _):
                __sectionUpdated.append(i)
            case .sectionMove(fromOffset: _, toOffset: _, element: _):
                __sectionMoved.append(i)
            case .elementRemove(offset: _, section: _, element: _):
                __elementRemoved.append(i)
            case .elementInsert(offset: _, section: _, element: _):
                __elementInserted.append(i)
            case .elementUpdate(offset: _, section: _, oldElement: _, newElement: _):
                __elementUpdated.append(i)
            case .elementMove(fromOffset: _, fromSection: _, toOffset: _, toSection: _, element: _):
                __elementMoved.append(i)
            }
        }

        if !sorted {
            __sectionRemoved.sort {$0.offset < $1.offset}
            __sectionInserted.sort {$0.offset < $1.offset}
            __sectionUpdated.sort {$0.offset < $1.offset}
            __sectionMoved.sort {$0.offset < $1.offset}
            __elementRemoved.sort {$0.offset < $1.offset}
            __elementInserted.sort {$0.offset < $1.offset}
            __elementUpdated.sort {$0.offset < $1.offset}
            __elementMoved.sort {$0.offset < $1.offset}
        }

        self.sectionRemoved = __sectionRemoved
        self.sectionInserted = __sectionInserted
        self.sectionUpdated = __sectionUpdated
        self.sectionMoved = __sectionMoved
        self.elementRemoved = __elementRemoved
        self.elementInserted = __elementInserted
        self.elementUpdated = __elementUpdated
        self.elementMoved = __elementMoved

        var allChanges:[Change] = []
        allChanges.append(contentsOf: self.sectionMoved)
        allChanges.append(contentsOf: self.sectionInserted)
        allChanges.append(contentsOf: self.sectionUpdated)
        allChanges.append(contentsOf: self.sectionMoved)
        allChanges.append(contentsOf: self.elementRemoved)
        allChanges.append(contentsOf: self.elementRemoved)
        allChanges.append(contentsOf: self.elementUpdated)
        allChanges.append(contentsOf: self.elementMoved)
        self.allChanges = allChanges
    }

}

//MARK: - Collection
extension RDADifference: Collection {

    public typealias Element = RDADifference.Change
    public typealias Index = Int

    public func index(after i: Int) -> Int {
        return self.allChanges.index(after: i)
    }

    public func index(_ i: Int, offsetBy distance: Int) -> Int {
        return self.allChanges.index(i, offsetBy: distance)
    }

    public func index(_ i: Int, offsetBy distance: Int, limitedBy limit: Int) -> Int? {
        return self.allChanges.index(i, offsetBy: distance, limitedBy: limit)
    }

    public var startIndex: Index {return self.allChanges.startIndex}

    public var endIndex: Index {return self.allChanges.endIndex}

    public subscript(position: Int) -> RDADifference<SectionElement, RowElement>.Change {
        return self.allChanges[position]
    }

}
