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

///an array that can return changes, idea from DeepDiff: https://github.com/onmyway133/DeepDiff and DifferenceKit: https://github.com/ra1028/DifferenceKit
public class RXCDiffArray<Element>: Collection {

    public struct Key {
        ///用于伪装Section
        public static var fakeSection:String {return "fakeSection"}
    }

    public typealias Iterator = RXCDiffArray.RXCIterator<Element>

    public var startIndex: Int {return 0}

    public var endIndex: Int {return self.contentArray.count-1}

    public func index(after i: Int) -> Int {
        return i + 1
    }

    //TODO: 是否可以考虑采用ContiguousArray? 或者采用可选的初始化类型
    ///实际存储数据的数组
    public var contentArray:[Element] = []

    public var threadSafe:Bool = true

    required public init() {

    }

    public convenience init(objects:Element...) {
        self.init()
        self.contentArray.append(contentsOf: objects)
    }

    public convenience init(objects:[Element]) {
        self.init()
        self.contentArray.append(contentsOf: objects)
    }

    //MARK: - Lock

    private func lockContent() {
        objc_sync_enter(self.contentArray)
    }

    private func unlockContent() {
        objc_sync_exit(self.contentArray)
    }

    //MARK: - 下面是一维数据的操作



    //MARK:- 一维 R

    public var count:Int {return self.contentArray.count}

    public var isEmpty:Bool {return self.contentArray.isEmpty}

    public func safeGet(at index:Int) -> Element? {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        if index < 0 || index >= self.count {
            return nil
        }

        return self[index]
    }

    public var first:Element? {
        return self.contentArray.first
    }

    public var last:Element? {
        return self.contentArray.last
    }

    public func first(where predicate: (Element) throws -> Bool) rethrows -> Element? {
        do {return try self.contentArray.first(where: predicate)}catch {throw error}
    }

    public func last(where predicate: (Element) throws -> Bool) rethrows -> Element? {
        do {return try self.contentArray.last(where: predicate)}catch {throw error}
    }

    public func firstIndex(where predicate: (Element) throws -> Bool) rethrows -> Int? {
        do {return try self.contentArray.firstIndex(where: predicate)}catch {throw error}
    }

    public func lastIndex(where predicate: (Element) throws -> Bool) rethrows -> Int? {
        do {return try self.contentArray.lastIndex(where: predicate)}catch {throw error}
    }

    //MARK: - C

    @discardableResult
    public func add(_ anObject: Element, userInfo:[AnyHashable:Any]?=nil)->RDAChangeSet<Element> {
        self.insert(contentOf: [anObject], at: self.count, userInfo: userInfo)
    }

    @discardableResult
    public func add(contentsOf objects: [Element], userInfo:[AnyHashable:Any]?=nil)->RDAChangeSet<Element> {
        return self.insert(contentOf: objects, at: self.count, userInfo: userInfo)
    }

    @discardableResult
    public func insert(_ anObject:Element, at index:Int, userInfo:[AnyHashable:Any]?=nil)->RDAChangeSet<Element> {
        return self.insert(contentOf: [anObject], at: index, userInfo: userInfo)
    }

    @discardableResult
    public func insert(contentOf objects:[Element], at index:Int, userInfo:[AnyHashable:Any]?=nil)->RDAChangeSet<Element> {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        let range:Range<Int> = index..<index+objects.count
        self.contentArray.insert(contentsOf: objects, at: index)

        let __section = userInfo?[RXCDiffArray.Key.fakeSection] as? Int ?? 0
        let changes:[RDAChangeSet<Element>.Change] = range.map({
            let insert = RDAChangeSet<Element>.ElementInsert(item: objects[$0-range.startIndex], index: $0, section: __section)
            return RDAChangeSet<Element>.Change.elementInsert(insert)
        })
        return RDAChangeSet(changes: changes)
    }

    //MARK: - U

    @discardableResult
    public func replace(at index: Int, with anObject: Element,userInfo:[AnyHashable:Any]?=nil)->RDAChangeSet<Element> {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        let old = self[index]
        self.contentArray[index] = anObject

        let __section = userInfo?[RXCDiffArray.Key.fakeSection] as? Int ?? 0
        let change = RDAChangeSet<Element>.Change.elementUpdate(RDAChangeSet<Element>.ElementUpdate(oldItem: old, newItem: anObject, index: index, section: __section))
        return RDAChangeSet(changes: [change])
    }

    ///re-set the object so we have a chance to send change, drive the UI to refresh, only send change, nothing else will happen
    @discardableResult
    public func reload(at index:Int,userInfo:[AnyHashable:Any]?=nil)->RDAChangeSet<Element> {
        let element = self[index]
        let __section = userInfo?[RXCDiffArray.Key.fakeSection] as? Int ?? 0
        let change = RDAChangeSet.Change.elementUpdate(RDAChangeSet.ElementUpdate(oldItem: element, newItem: element, index: index, section: __section))
        return RDAChangeSet(changes: [change])
    }

    @discardableResult
    public func move(from fromIndex:Int, to toIndex:Int, userInfo:[AnyHashable:Any]?=nil)->RDAChangeSet<Element> {
        guard fromIndex != toIndex else {return RDAChangeSet.empty()}

        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        let fromValue = self.contentArray[fromIndex]
        self.contentArray.remove(at: fromIndex)
        self.contentArray.insert(fromValue, at: toIndex)

        let __section = userInfo?[RXCDiffArray.Key.fakeSection] as? Int ?? 0
        let change = RDAChangeSet.ElementMove(item: fromValue, fromIndex: fromIndex, fromSection: __section, toIndex: toIndex, toSection: __section)
        let changeEnum = RDAChangeSet.Change.elementMove(change)
        return RDAChangeSet(changes: [changeEnum])
    }
/*
    ///未经测试
    @discardableResult
    fileprivate func exchange(index1:Int, index2:Int, userInfo:[AnyHashable:Any]?=nil)->RDAChangeSet<Element> {

        guard index1 != index2 else {return RDAChangeSet.empty()}

        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        let value1 = self[index1]
        let value2 = self[index2]

        self.replace(at: index1, with: value2)
        self.replace(at: index2, with: value1)

        let move1 = RDAChangeSet.ElementMove(item: value1, fromIndex: index1, fromSection: 0, toIndex: index2, toSection: 0)
        let move2 = RDAChangeSet.ElementMove(item: value2, fromIndex: index2, fromSection: 0, toIndex: index1, toSection: 0)
        let change1 = RDAChangeSet.Change.elementMove(move1)
        let change2 = RDAChangeSet.Change.elementMove(move2)
        return RDAChangeSet(changes: [change1, change2])
    }
 */

    //MARK: - D

    @discardableResult
    public func remove(at index: Int, userInfo:[AnyHashable:Any]?=nil)->RDAChangeSet<Element> {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        let removed = self.contentArray[index]
        self.contentArray.remove(at: index)

        let __section = userInfo?[RXCDiffArray.Key.fakeSection] as? Int ?? 0
        let change = RDAChangeSet.ElementDelete(item: removed, index: index, section: __section)
        let changeEnum = RDAChangeSet.Change.elementDelete(change)
        return RDAChangeSet(changes: [changeEnum])
    }

    @discardableResult
    public func removeAll(where predicate: (Element) -> Bool, userInfo:[AnyHashable:Any]?=nil)->RDAChangeSet<Element> {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        let __section = userInfo?[RXCDiffArray.Key.fakeSection] as? Int ?? 0
        var changes:[RDAChangeSet<Element>.Change] = [RDAChangeSet<Element>.Change]()

        for i in self.contentArray.enumerated() {
            if predicate(i.element) {
                let change = RDAChangeSet.ElementDelete(item: i.element, index: i.offset, section: __section)
                changes.append(RDAChangeSet.Change.elementDelete(change))
            }
        }
        //删除本地数据
        for i in changes.reversed() {
            switch i {
            case .elementDelete(let delete):
                self.contentArray.remove(at: delete.index)
            default:
                break
            }
        }

        return RDAChangeSet(changes: changes)
    }

    @discardableResult
    public func removeAll(userInfo:[AnyHashable:Any]?=nil)->RDAChangeSet<Element> {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        let __section = userInfo?[RXCDiffArray.Key.fakeSection] as? Int ?? 0
        let changes = self.contentArray.enumerated().map { (offset:Int, element:Element) -> RDAChangeSet<Element>.Change in
            let change = RDAChangeSet.ElementDelete(item: element, index: offset, section: __section)
            return RDAChangeSet.Change.elementDelete(change)
        }
        self.contentArray.removeAll()
        return RDAChangeSet(changes: changes)
    }

    ///删除前面几个元素, 这里的k可以大于元素数量而不会崩溃
    @discardableResult
    public func removeFirst(k:Int=1, userInfo:[AnyHashable:Any]?=nil)->RDAChangeSet<Element> {
        if self.contentArray.isEmpty {return RDAChangeSet.empty()}

        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        let __section = userInfo?[RXCDiffArray.Key.fakeSection] as? Int ?? 0
        let range = 0..<(k > self.contentArray.count ? self.contentArray.count : k)
        let changes:[RDAChangeSet<Element>.Change] = range.map { (offset) -> RDAChangeSet<Element>.Change in
            let element = self.contentArray[offset]
            let change = RDAChangeSet.ElementDelete(item: element, index: offset, section: __section)
            return RDAChangeSet.Change.elementDelete(change)
        }
        self.contentArray.removeSubrange(range)
        return RDAChangeSet(changes: changes)
    }

    @discardableResult
    public func removeLast(k:Int=1)->RDAChangeSet<Element> {
        if self.contentArray.isEmpty {return RDAChangeSet.empty()}
        let end = self.contentArray.count
        var start:Int = end - k
        if start < 0 {start = 0}
        let range = start..<end


    }

    //MARK: - subscript

    public subscript(index:Int) -> Element {
        get {
            return self.contentArray[index] as! Element
        }
    }

    public subscript(bounds:Range<Int>) -> [Element] {
        get {
            var arr:[Element] = []
            for i in bounds {
                arr.append(self[i])
            }
            return arr
        }
    }

    public subscript(bounds:ClosedRange<Int>)->[Element] {
        get {
            var arr:[Element] = []
            for i in bounds {
                arr.append(self[i])
            }
            return arr
        }
    }

    //MARK: - Sequence

    public func makeIterator() -> RXCDiffArray.RXCIterator<Element> {
        return RXCDiffArray.RXCIterator<Element>(self)
    }

    //MARK: - RangeReplaceableCollection

    

}

public extension RXCDiffArray {

    struct RXCIterator<Element>: IteratorProtocol {

        private let array:RXCDiffArray<Element>
        private var index:Int = 0

        public init(_ array:RXCDiffArray<Element>){
            self.array = array
        }

        public mutating func next() -> Element? {
            let object = array.safeGet(at: index)
            index += 1
            return object
        }
    }

}

//MARK: - Equatable

extension RXCDiffArray: Equatable where Element: Equatable {

    public static func == (lhs: RXCDiffArray, rhs: RXCDiffArray) -> Bool {
        if lhs.count != rhs.count {return false}
        for i in 0..<lhs.count {
            if lhs.safeGet(at: i) != rhs.safeGet(at: i) {
                return false
            }
        }
        return true
    }

}

//MARK: - DeepDiff

#if canImport(DeepDiff)
extension RXCDiffArray where Element: DiffAware {

//    public func batch(batchClosure:()->()) {
//        let old:[Element] = [Element].init(self)
//        batchClosure()
//        let new:[Element] = [Element].init(self)
//        let changes = DeepDiff.diff(old: old, new: new)
//        return changes
//    }

}
#endif

public extension RXCDiffArray where Element: RDASectionElementProtocol {

    typealias SubElement = Element.RDAElementType

    //MARK: - 2D C

    @discardableResult
    func add(_ anObject: SubElement, in section:Int)->RDAChangeSet<SubElement> {
        return self.add(contentsOf: [anObject], in: section)
    }

    @discardableResult
    func add(contentsOf objects: [SubElement], in section:Int)->RDAChangeSet<SubElement> {
        return self.insert(contentOf: objects, at: self.count, in: section)
    }

    @discardableResult
    func insert(_ anObject:SubElement, at index:Int,in section:Int)->RDAChangeSet<SubElement> {
        return self.insert(contentOf: [anObject], at: index, in: section)
    }

    @discardableResult
    func insert(contentOf objects:[SubElement], at index:Int, in section:Int)->RDAChangeSet<SubElement> {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        var sectionElement = self[section]
        sectionElement.rda_elements.insert(contentsOf: objects, at: index)
        self.contentArray.replaceObject(at: section, with: sectionElement)

        let range:Range<Int> = index..<index+objects.count
        let changes:[RDAChangeSet<SubElement>.Change] = range.map({
            let insert = RDAChangeSet<SubElement>.ElementInsert(item: objects[$0-range.startIndex], index: index, section: section)
            return RDAChangeSet<SubElement>.Change.elementInsert(insert)
        })
        return RDAChangeSet<SubElement>(changes: changes)
    }

    //MARK: - 2D U

    @discardableResult
    func replace(with anObject: SubElement, at index: Int, in section:Int)->RDAChangeSet<SubElement> {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        var sectionElement = self[section]
        let old = sectionElement.rda_elements[index]
        sectionElement.rda_elements[index] = anObject
        self.contentArray[section] = sectionElement

        let change = RDAChangeSet.Change.elementUpdate(RDAChangeSet.ElementUpdate(oldItem: old, newItem: anObject, index: index, section: section))
        return RDAChangeSet(changes: [change])
    }

    ///re-set the object so we have a chance to send change, drive the UI to refresh
    @discardableResult
    func reload(at index:Int, in section:Int)->RDAChangeSet<SubElement> {
        //send changes directly
        let sectionElement = self[section]
        let element = sectionElement.rda_elements[index]
        let change = RDAChangeSet.Change.elementUpdate(RDAChangeSet.ElementUpdate(oldItem: element, newItem: element, index: index, section: section))
        return RDAChangeSet(changes: [change])
    }

    @discardableResult
    func move(fromIndex:Int,fromSection:Int, toIndex:Int, toSection:Int)->RDAChangeSet<SubElement> {

        guard fromIndex != toIndex && fromSection != toSection else {return RDAChangeSet.empty()}

        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        var fromSectionElement = self[fromSection]
        let fromElement = fromSectionElement.rda_elements[fromIndex]
        var toSectionElement = self[toSection]

        fromSectionElement.rda_elements.remove(at: fromIndex)
        toSectionElement.rda_elements.insert(fromElement, at: toIndex)
        self.contentArray[fromSection] = fromSectionElement
        self.contentArray[toSection] = toSectionElement

        let change = RDAChangeSet.ElementMove(item: fromElement, fromIndex: fromIndex, fromSection: fromSection, toIndex: toIndex, toSection: toSection)
        let changeEnum = RDAChangeSet.Change.elementMove(change)
        return RDAChangeSet(changes: [changeEnum])
    }

    //MARK: - D

    @discardableResult
    func remove(at index: Int, in section:Int)->RDAChangeSet<SubElement> {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        var sectionElement = self[section]
        let removed = sectionElement.rda_elements[index]
        sectionElement.rda_elements.remove(at: index)
        self.contentArray[section] = sectionElement

        let change = RDAChangeSet.ElementDelete(item: removed, index: index, section: section)
        let changeEnum = RDAChangeSet.Change.elementDelete(change)
        return RDAChangeSet(changes: [changeEnum])
    }

    @discardableResult
    func removeAll(in section:Int, where predicate: (SubElement) -> Bool)->RDAChangeSet<SubElement> {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        var changes:[RDAChangeSet<SubElement>.Change] = [RDAChangeSet<SubElement>.Change]()
        var sectionElement = self[section]
        for i in sectionElement.rda_elements.enumerated() {
            if predicate(i.element) {
                let change = RDAChangeSet.ElementDelete(item: i.element, index: i.offset, section: section)
                changes.append(RDAChangeSet.Change.elementDelete(change))
            }
        }
        //删除本地数据
        for i in changes.reversed() {
            switch i {
            case .elementDelete(let delete):
                sectionElement.rda_elements.remove(at: delete.index)
            default:
                break
            }
        }
        self.contentArray[section] = sectionElement

        return RDAChangeSet(changes: changes)
    }

    @discardableResult
    func removeAll(in section:Int)->RDAChangeSet<SubElement> {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        var sectionElement = self[section]

        let changes = sectionElement.rda_elements.enumerated().map {(i) -> RDAChangeSet<SubElement>.Change in
            let change = RDAChangeSet.ElementDelete(item: i.element, index: i.offset, section: section)
            return RDAChangeSet.Change.elementDelete(change)
        }

        sectionElement.rda_elements.removeAll()
        self.contentArray[section] = sectionElement

        return RDAChangeSet(changes: changes)
    }

    @discardableResult
    func dropFirst(in section:Int)->RDAChangeSet<SubElement> {
        if self.isEmpty {return RDAChangeSet.empty()}
        return self.remove(at: 0, in: section)
    }

    @discardableResult
    func dropLast(in section:Int)->RDAChangeSet<SubElement> {
        if self.isEmpty {return RDAChangeSet.empty()}
        let sectionElement = self[section]
        return self.remove(at: sectionElement.rda_elements.count-1, in: section)
    }

    subscript(indexPath:IndexPath)->SubElement {
        let sectionElement = self[indexPath.section]
        return sectionElement.rda_elements[indexPath.item]
    }

}

//MARK: - DifferenceKit
#if canImport(DifferenceKit)
public extension RXCDiffArray where Element: Differentiable {

    /// 进行一维对比, 元素的变化视为 Section 的变化
    func batch_differenceKit_linear(batch:()->Void)->RDAChangeSet<Element> {
        let old = [Element].init(self)
        batch()
        let new = [Element].init(self)
        let dk_changeset = StagedChangeset(source: old, target: new)

        var mappedChanges:[RDAChangeSet<Element>.Change] = []

        for dk_change in dk_changeset {
            for i in dk_change.elementDeleted {
                let change = RDAChangeSet.SectionDelete(item: old[i.element], index: i.element)
                mappedChanges.append(RDAChangeSet.Change.sectionDelete(change))
            }
            for i in dk_change.elementMoved {
                let change = RDAChangeSet.SectionMove(item: old[i.source.element], fromIndex: i.source.element, toIndex: i.target.element)
                mappedChanges.append(RDAChangeSet.Change.sectionMove(change))
            }
            for i in dk_change.elementUpdated {
                let change = RDAChangeSet.SectionUpdate(oldItem: old[i.element], newItem: new[i.element], index: i.element)
                
            }


        }

    }

}
#endif
