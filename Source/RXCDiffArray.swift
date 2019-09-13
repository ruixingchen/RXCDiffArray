//
//  RXCDiffArray.swift
//  RXCDiffArrayExample
//
//  Created by ruixingchen on 7/12/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import Foundation
#if canImport(DifferenceKit)
import DifferenceKit
#endif

//对一维结构, 数据的操作默认是在Section 0 中进行的

public protocol SectionElementProtocol {
    
    ///容纳第二维数据的容器类型, 一般是数组类型, 只支持 Index 为 Int 的类型
    associatedtype ElementContainer: RangeReplaceableCollection
    
    var rda_elements:ElementContainer {get set}

}

public protocol RXCDiffArrayDelegate: AnyObject {

    func diffArray<SectionContainer: RangeReplaceableCollection>(array:RXCDiffArray<SectionContainer>, didChange difference:RDADifference<SectionContainer.Element,SectionContainer.Element.ElementContainer.Element>) where SectionContainer.Element: SectionElementProtocol

}

///默认使用二维数据结构

///思想涞源 DeepDiff: https://github.com/onmyway133/DeepDiff and DifferenceKit: https://github.com/ra1028/DifferenceKit

/// 范型表示Section的数据的容器类型, 一般是一个Array类型, 如RXCDiffArray<[Card]>, 兼容其他类型, 如连续数组

public final class RXCDiffArray<SectionContainer: RangeReplaceableCollection> where SectionContainer.Element: SectionElementProtocol  {
    
    public typealias Element = SectionContainer.Element
    public typealias Index = SectionContainer.Index
    
    public typealias SectionElement = SectionContainer.Element
    public typealias SubElement = SectionContainer.Element.ElementContainer.Element
    public typealias SectionIndex = SectionContainer.Index
    public typealias SubElementIndex = SectionContainer.Element.ElementContainer.Index

    public typealias Difference = RDADifference<SectionElement, SubElement>

    public struct Key {
        ///是否通知代理
        static var notify:String {return "notify"}
    }
    
    internal var contentCollection:SectionContainer
    
    ///default we are not thread safe
    public var threadSafe:Bool = false

    public weak var delegate:RXCDiffArrayDelegate?

    public init() {
        self.contentCollection = SectionContainer.init()
    }
    
    public init(repeating repeatedValue: Element, count: Int) {
        self.contentCollection = SectionContainer.init(repeating: repeatedValue, count: count)
    }

    public var count: Int {return self.contentCollection.count}

    public var isEmpty: Bool {return self.contentCollection.isEmpty}

    //MARK: - Tool

    internal func lockContent() {
        objc_sync_enter(self.contentCollection)
    }
    
    internal func unlockContent() {
        objc_sync_exit(self.contentCollection)
    }

    internal func notifyDelegate(diff:RDADifference<SectionElement, SubElement>, userInfo:[AnyHashable:Any]?) {
        if userInfo?[RXCDiffArray.Key.notify] as? Bool ?? true {
            //only false works, anything else is *true*
            self.delegate?.diffArray(array: self, didChange: diff)
        }
    }
    
}

//MARK: - Section 操作
extension RXCDiffArray where SectionContainer.Index==Int {
    
    @discardableResult
    public func rda_appendSection(_ newElement: __owned SectionElement, userInfo:[AnyHashable:Any]?=nil)->Difference {
        return self.rda_appendSection(contentsOf: CollectionOfOne(newElement), userInfo: userInfo)
    }
    
    @discardableResult
    public func rda_appendSection<S>(contentsOf newElements: __owned S, userInfo:[AnyHashable:Any]?=nil)->Difference where S : Sequence, Element == S.Element {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}
        
        let startIndex = self.contentCollection.endIndex
        let changes:[Difference.Change] = newElements.enumerated().map { (i) -> Difference.Change in
            let index = self.contentCollection.index(startIndex, offsetBy: i.offset)
            return Difference.Change.sectionInsert(offset: index, element: i.element)
        }
        
        let diff = Difference(changes: changes)
        self.notifyDelegate(diff: diff, userInfo: userInfo)
        return diff
    }

    @discardableResult
    public func rda_insertSection(_ newElement: __owned SectionElement, at i: SectionIndex, userInfo:[AnyHashable:Any]?=nil)->Difference {
        return self.rda_insertSection(contentsOf: CollectionOfOne(newElement), at: i, userInfo: userInfo)
    }

    @discardableResult
    public func rda_insertSection<C>(contentsOf newElements: __owned C, at i: SectionIndex, userInfo:[AnyHashable:Any]?=nil)->Difference where C : Collection, C.Element==SectionElement {
        
        //生成Change
        let changes:[Difference.Change] = newElements.enumerated().map {
            let targetIndex = self.contentCollection.index(i, offsetBy: $0.offset)
            return Difference.Change.sectionInsert(offset: targetIndex, element: $0.element)
        }

        self.contentCollection.insert(contentsOf: newElements, at: i)

        let diff = Difference(changes: changes)
        self.notifyDelegate(diff: diff, userInfo: userInfo)
        return diff
    }
    
    ///用一组数据替换数据源中某一个部分的数据

    @available(*, deprecated, message: "没有充分测试, 谨慎使用")
    @discardableResult
    public func rda_replaceSection<C:Collection, R:RangeExpression>(_ subrange: R, with newElements: __owned C, userInfo:[AnyHashable:Any]?=nil)->Difference where C.Element==RXCDiffArray.Element, R.Bound==RXCDiffArray.Index {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}
        
        ///传入的可能是一个含有无限的范围, 先获取真实的范围
        let realRange:Range<SectionIndex> = subrange.relative(to: self.contentCollection)
        
        ///将本地集合的index转换为新数据的index
        func indexToNewElementIndex(index:SectionIndex)->C.Index {
            let distance = realRange.distance(from: index, to: realRange.startIndex)
            return newElements.index(newElements.startIndex, offsetBy: distance)
        }
        
        var changes:[Difference.Change] = []
        
        //重合部分的长度
        let even:Int = Swift.min(realRange.distance(from: realRange.startIndex, to: realRange.endIndex), newElements.distance(from: newElements.startIndex, to: newElements.endIndex))
        
        if true {
            //重合部分转换成sectionUpdate
            let upperIndex = realRange.index(realRange.startIndex, offsetBy: even)
            for i:SectionIndex in realRange.startIndex..<upperIndex {
                //公共部分为替换数据
                let oldElement = self.contentCollection[i]
                //这是第几次循环
                let indexForNewElement = indexToNewElementIndex(index: i)
                let newElement = newElements[indexForNewElement]
                let change = Difference.Change.sectionUpdate(offset: i, oldElement: oldElement, newElement: newElement)
                changes.append(change)
            }
        }
        //两个部分长度的差值
        let uneven = newElements.count - realRange.count
        let startIndex:SectionIndex = realRange.index(realRange.startIndex, offsetBy: even)
        if uneven > 0 {
            //新数据的长度大于原始片段长度, 超出的部分视为插入的数据
            // ----
            // ----------
            let endIndex = realRange.index(realRange.startIndex, offsetBy: newElements.count)
            for i in startIndex..<endIndex {
                let indexForNewElement = indexToNewElementIndex(index: i)
                let element = newElements[indexForNewElement]
                let change = Difference.Change.sectionInsert(offset: i, element: element)
                changes.append(change)
            }
        }else if uneven < 0 {
            //新数据 < 原始片段, 超出的部分视为删除数据
            // --------
            // ----
            let endIndex = realRange.endIndex
            for i in startIndex..<endIndex {
                let element = self.contentCollection[i]
                let change = Difference.Change.sectionRemove(offset: i, element: element)
                changes.append(change)
            }
        }
        
        self.contentCollection.replaceSubrange(subrange, with: newElements)
        
        let diff = Difference(changes: changes)
        self.notifyDelegate(diff: diff, userInfo: userInfo)
        return diff
    }

    ///删除Section
    @discardableResult
    public func rda_removeSection(at position: SectionIndex, userInfo:[AnyHashable:Any]?=nil) -> Difference {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}
        return self.rda_removeSection(position..<self.contentCollection.index(position, offsetBy: 1), userInfo: userInfo)
    }
    
    @discardableResult
    public func rda_removeSection(_ bounds: Range<SectionContainer.Index>, userInfo:[AnyHashable:Any]?=nil)->Difference {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}
        
        let changes:[Difference.Change] = bounds.map({
            let change = Difference.Change.sectionRemove(offset: $0, element: self.contentCollection[$0])
            return change
        })
        
        self.contentCollection.removeSubrange(bounds)
        
        let diff = Difference(changes: changes)
        self.notifyDelegate(diff: diff, userInfo: userInfo)
        return diff
    }
    
    ///删除所有符合条件的一维数据
    @discardableResult
    public func rda_removeAllSection(userInfo:[AnyHashable:Any]?=nil, where shouldBeRemoved: (SectionContainer.Element) -> Bool)->Difference {
        
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}
        
        var removedElement:[SectionElement] = []
        var removedIndex:[SectionIndex] = []
        
        for i in (0..<self.contentCollection.count).reversed() {
            if shouldBeRemoved(self.contentCollection[i]) {
                removedIndex.append(i)
                removedElement.append(self.contentCollection.remove(at: i))
            }
        }
        
        let diff:Difference
        if !removedElement.isEmpty {
            var changes:[Difference.Change] = []
            for i in (0..<removedElement.count).reversed() {
                //从小向大遍历
                let element = removedElement[i]
                let index = removedIndex[i]
                changes.append(Difference.Change.sectionRemove(offset: index, element: element))
            }
            diff = Difference(changes: changes)
        }else {
            diff = Difference.empty()
        }
        self.notifyDelegate(diff: diff, userInfo: userInfo)
        return diff
    }

    ///移动Section
    @discardableResult
    public func rda_moveSection(from position:SectionIndex, to toPosition:SectionIndex,userInfo:[AnyHashable:Any]?=nil)->Difference {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        let element = self.contentCollection.remove(at: position)
        self.contentCollection.insert(element, at: toPosition)
        
        let change = Difference.Change.sectionMove(fromOffset: position, toOffset: toPosition, element: element)
        
        let diff = Difference(changes: CollectionOfOne(change))
        self.notifyDelegate(diff: diff, userInfo: userInfo)
        return diff
    }
    
}

//MARK: - 二维元素操作
extension RXCDiffArray where SectionIndex==Int, SubElementIndex==Int {
    
    public func rda_append(_ newElement: __owned SubElement, in s:SectionIndex, userInfo:[AnyHashable:Any]?=nil)->Difference {
        return self.rda_append(contentsOf: CollectionOfOne(newElement), in: s, userInfo: userInfo)
    }

    public func rda_append<S>(contentsOf newElements: __owned S, in s:SubElementIndex, userInfo:[AnyHashable:Any]?=nil)->Difference where S : Collection, S.Element==SubElement {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}
        
        
    }

    public func rda_insert(_ newElement: __owned SubElement, at i: SubElementIndex, in s:SectionIndex, userInfo:[AnyHashable:Any]?=nil)->Difference {
        return self.rda_insert(contentsOf: CollectionOfOne(newElement), at: i, in: s, userInfo: userInfo)
    }

    public func rda_insert<C>(contentsOf newElements: __owned C, at i: SubElementIndex, in s:SectionIndex, userInfo:[AnyHashable:Any]?=nil)->Difference where C : Collection,C.Element==SubElement {
        
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}
        
        //生成Change
        let changes:[Difference.Change] = newElements.enumerated().map {
            let index = self.contentCollection.index(i, offsetBy: $0.offset)
            return Difference.Change.elementInsert(offset: index, section: s, element: $0.element)
        }
        
        var section = self.contentCollection[s]
        section.rda_elements.insert(contentsOf: newElements, at: i)
        let endIndex = self.contentCollection.index(s, offsetBy: 1)
        self.contentCollection.replaceSubrange(s..<endIndex, with: CollectionOfOne(section))
    
        let diff = Difference(changes: changes)
        self.notifyDelegate(diff: diff, userInfo: userInfo)
        return diff
    }
    
    public func rda_remove(_ bounds: Range<SubElementIndex>, userInfo:[AnyHashable:Any]?=nil)->Difference {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}
        
        let changes:[Difference.Change] = bounds.map({
            let change = Difference.Change.sectionRemove(offset: $0, element: self.contentCollection[$0])
            return change
        })
        
        self.contentCollection.removeSubrange(bounds)
        
        let diff = Difference(changes: changes)
        self.notifyDelegate(diff: diff, userInfo: userInfo)
        return diff
    }

    ///删除Section
    public func rda_remove(at position: SubElementIndex, in s:SectionIndex
    ) -> Difference {
        let change = Difference.Change.sectionRemove(offset: position, element: element)
        
        let element = self.contentCollection.remove(at: position)
        
        return Difference(changes: [change])
    }
    
    ///删除某个Section中的一段数据
    public func rda_remove(_ bounds:Range<SubElementIndex>, in s:SectionIndex)->Difference {
        
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}
        
        var section = self.contentCollection[s]
        var element = section.rda_elements
        element.removeSubrange(bounds)
        section.rda_elements = element
        let endIndex = self.contentCollection.index(s, offsetBy: 1)
        self.contentCollection.replaceSubrange(s..<endIndex, with: CollectionOfOne(section))
        
        let changes:[Difference.Change] = bounds.map {
            let change = Difference.Change.elementRemove(offset: $0, section: s, element: <#T##SectionContainer.Element.ElementContainer.Element#>)
        }
        
    }

    ///移动Section
    public func rda_move(from position:Int, to toPosition:Int)->Difference {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        let element = self.contentCollection.remove(at: position)
        self.contentCollection.insert(element, at: toPosition)

        let change = Difference.Change.sectionMove(fromOffset: position, toOffset: toPosition, element: element)
        return Difference(changes: [change])
    }
    
}

extension RXCDiffArray: Collection {

    public var startIndex: SectionContainer.Index {return self.contentCollection.startIndex}

    public var endIndex: SectionContainer.Index {return self.contentCollection.endIndex}

    public subscript(position: SectionContainer.Index) -> SectionContainer.Element {
        return self.contentCollection[position]
    }

    public func index(after i: SectionContainer.Index) -> SectionContainer.Index {
        return self.contentCollection.index(after: i)
    }

    public var underestimatedCount: Int {return self.contentCollection.underestimatedCount}

}

extension RXCDiffArray: RangeReplaceableCollection {
    

}
