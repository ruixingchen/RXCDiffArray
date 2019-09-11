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
public class RXCDiffArray<RDAElement>: Collection {

    public struct Key {
        ///用于伪装Section
        public static var fakeSection:String {return "fakeSection"}
    }

    public typealias Element = RDAElement
    public typealias Index = Int

    public var startIndex: Int {return self.contentArray.startIndex}

    public var endIndex: Int {return self.contentArray.endIndex}

    public func index(after i: Int) -> Int {
        return self.contentArray.index(after: i)
    }

    //TODO: 是否可以考虑采用ContiguousArray? 或者采用范型来自由选择合适的集合类型
    ///实际存储数据的数组
    public var contentArray:[RDAElement] = []

    public var threadSafe:Bool = true

    public convenience init(objects:RDAElement...) {
        self.init()
        self.contentArray.append(contentsOf: objects)
    }

    public convenience init(objects:[RDAElement]) {
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

    public func safeGet(at index:Int) -> RDAElement? {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        if index < 0 || index >= self.count {
            return nil
        }

        return self[index]
    }
/*
    public var count:Int {return self.contentArray.count}

    public var isEmpty:Bool {return self.contentArray.isEmpty}



    public var first:RDAElement? {
        return self.contentArray.first
    }

    public var last:RDAElement? {
        return self.contentArray.last
    }

    public func first(where predicate: (RDAElement) throws -> Bool) rethrows -> RDAElement? {
        do {return try self.contentArray.first(where: predicate)}catch {throw error}
    }

    public func last(where predicate: (RDAElement) throws -> Bool) rethrows -> RDAElement? {
        do {return try self.contentArray.last(where: predicate)}catch {throw error}
    }

    public func firstIndex(where predicate: (RDAElement) throws -> Bool) rethrows -> Int? {
        do {return try self.contentArray.firstIndex(where: predicate)}catch {throw error}
    }

    public func lastIndex(where predicate: (RDAElement) throws -> Bool) rethrows -> Int? {
        do {return try self.contentArray.lastIndex(where: predicate)}catch {throw error}
    }
     */

    //MARK: - C

    @discardableResult
    public func add(_ anObject: RDAElement, userInfo:[AnyHashable:Any]?=nil)->RDADifference<RDAElement> {
        self.insert(contentOf: [anObject], at: self.count, userInfo: userInfo)
    }

    @discardableResult
    public func add<C:Collection>(contentsOf objects: C, userInfo:[AnyHashable:Any]?=nil) ->RDADifference<RDAElement> where C.Element == RDAElement {
        return self.insert(contentOf: objects, at: self.count, userInfo: userInfo)
    }

    @discardableResult
    public func insert(_ anObject:RDAElement, at index:Int, userInfo:[AnyHashable:Any]?=nil)->RDADifference<RDAElement> {
        return self.insert(contentOf: [anObject], at: index, userInfo: userInfo)
    }

    @discardableResult
    public func insert<C:Collection>(contentOf objects:C, at index:Int, userInfo:[AnyHashable:Any]?=nil)->RDADifference<RDAElement> where C.Element == RDAElement {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        let __section = userInfo?[RXCDiffArray.Key.fakeSection] as? Int ?? 0
        let changes:[RDADifference<RDAElement>.Change] = objects.enumerated().map { (i) -> RDADifference<RDAElement>.Change in
            return RDADifference.Change.elementInsert(offset: i.offset+index, section: __section, element: i.element)
        }

        self.contentArray.insert(contentsOf: objects, at: index)

        return RDADifference(changes: changes)
    }

    //MARK: - U

    @discardableResult
    public func replace(at index: Int, with anObject: RDAElement,userInfo:[AnyHashable:Any]?=nil)->RDADifference<RDAElement> {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        let old = self[index]
        self.contentArray[index] = anObject

        let __section = userInfo?[RXCDiffArray.Key.fakeSection] as? Int ?? 0
        let change:RDADifference<RDAElement>.Change = RDADifference.Change.elementUpdate(offset: index, section: __section, oldElement: old, newElement: anObject)
        return RDADifference(changes: [change])
    }

    ///re-set the object so we have a chance to send change, drive the UI to refresh, only send change, nothing else will happen
    @discardableResult
    public func reload(at index:Int,userInfo:[AnyHashable:Any]?=nil)->RDADifference<RDAElement> {
        let element = self[index]
        let __section = userInfo?[RXCDiffArray.Key.fakeSection] as? Int ?? 0
        let change:RDADifference<RDAElement>.Change = RDADifference.Change.elementUpdate(offset: index, section: __section, oldElement: element, newElement: element)
        return RDADifference(changes: [change])
    }

    @discardableResult
    public func move(from fromIndex:Int, to toIndex:Int, userInfo:[AnyHashable:Any]?=nil)->RDADifference<RDAElement> {
        guard fromIndex != toIndex else {return RDADifference.empty()}

        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        let element = self.contentArray[fromIndex]
        self.contentArray.remove(at: fromIndex)
        self.contentArray.insert(element, at: toIndex)

        let __section = userInfo?[RXCDiffArray.Key.fakeSection] as? Int ?? 0
        let change = RDADifference.Change.elementMove(fromOffset: fromIndex, fromSection: __section, toOffset: toIndex, toSection: __section, element: element)
        return RDADifference(changes: [change])
    }

    #warning("not tested")
    @discardableResult
    fileprivate func exchange(index1:Int, index2:Int, userInfo:[AnyHashable:Any]?=nil)->RDADifference<Element> {

        guard index1 != index2 else {return RDADifference.empty()}

        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        let element1 = self[index1]
        let element2 = self[index2]

        self.replace(at: index1, with: element2)
        self.replace(at: index2, with: element2)

        let __section = userInfo?[RXCDiffArray.Key.fakeSection] as? Int ?? 0
        let move1 = RDADifference.Change.elementMove(fromOffset: index1, fromSection: __section, toOffset: index2, toSection: __section, element: element1)
        let move2 = RDADifference.Change.elementMove(fromOffset: index2, fromSection: __section, toOffset: index1, toSection: __section, element: element2)
        return RDADifference(changes: [move1, move2])
    }

    //MARK: - D

    @discardableResult
    public func remove(at index: Int, userInfo:[AnyHashable:Any]?=nil)->RDADifference<RDAElement> {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        let removedElement = self.contentArray[index]
        self.contentArray.remove(at: index)

        let __section = userInfo?[RXCDiffArray.Key.fakeSection] as? Int ?? 0
        let change = RDADifference.Change.elementRemove(offset: index, section: __section, element: removedElement)
        return RDADifference(changes: [change])
    }

    @discardableResult
    public func removeAll(where predicate: (RDAElement) -> Bool, userInfo:[AnyHashable:Any]?=nil)->RDADifference<RDAElement> {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        let __section = userInfo?[RXCDiffArray.Key.fakeSection] as? Int ?? 0
        var changes:[RDADifference<RDAElement>.Change] = [RDADifference<RDAElement>.Change]()

        for i in self.contentArray.enumerated() {
            if predicate(i.element) {
                let change = RDADifference.Change.elementRemove(offset: i.offset, section: __section, element: i.element)
                changes.append(change)
            }
        }
        //删除本地数据
        for i in changes.reversed() {
            switch i {
            case .elementRemove(offset: let offset, section: _, element: _):
                self.contentArray.remove(at: offset)
            default:
                break
            }
        }

        return RDADifference(changes: changes)
    }

    @discardableResult
    public func removeAll(userInfo:[AnyHashable:Any]?=nil)->RDADifference<RDAElement> {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        let __section = userInfo?[RXCDiffArray.Key.fakeSection] as? Int ?? 0
        let changes:[RDADifference<RDAElement>.Change] = self.contentArray.enumerated().map {
            let change = RDADifference.Change.elementRemove(offset: $0.offset, section: __section, element: $0.element)
            return change
        }
        self.contentArray.removeAll()
        return RDADifference(changes: changes)
    }

    ///删除前面几个元素, 这里的k可以大于元素数量而不会崩溃
    @discardableResult
    public func removeFirst(k:Int=1, userInfo:[AnyHashable:Any]?=nil)->RDADifference<RDAElement> {
        if self.contentArray.isEmpty {return RDADifference.empty()}

        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        let __section = userInfo?[RXCDiffArray.Key.fakeSection] as? Int ?? 0
        let range = 0..<(k > self.contentArray.count ? self.contentArray.count : k)
        let changes:[RDADifference<RDAElement>.Change] = range.map { (offset) -> RDADifference<RDAElement>.Change in
            let element = self.contentArray[offset]
            let change = RDADifference.Change.elementRemove(offset: offset, section: __section, element: element)
            return change
        }
        self.contentArray.removeSubrange(range)
        return RDADifference(changes: changes)
    }

    @discardableResult
    public func removeLast(k:Int=1, userInfo:[AnyHashable:Any]?=nil)->RDADifference<RDAElement> {
        if self.contentArray.isEmpty {return RDADifference.empty()}
        let end = self.contentArray.count
        var start:Int = end - k
        if start < 0 {start = 0}
        if start == end {return RDADifference.empty()}
        let range = start..<end

        let __section = userInfo?[RXCDiffArray.Key.fakeSection] as? Int ?? 0
        let changes:[RDADifference<RDAElement>.Change] = range.map({
            let change = RDADifference<RDAElement>.ElementDelete(item: self.contentArray[$0], index: $0, section: __section)
            return RDADifference.Change.elementDelete(change)
        })

        self.contentArray.removeSubrange(range)

        return RDADifference(changes: changes)
    }

    //MARK: - subscript

    public subscript(index:Int) -> RDAElement {
        get {
            return self.contentArray[index]
        }
    }

    public subscript(bounds:Range<Int>) -> [RDAElement] {
        get {
            return Array(self.contentArray[bounds])
        }
    }

    public subscript(bounds:ClosedRange<Int>)->[RDAElement] {
        get {
            return Array(self.contentArray[bounds])
        }
    }

    //MARK: - Sequence

    public func makeIterator() -> RXCDiffArray.RXCIterator<RDAElement> {
        return RXCDiffArray.RXCIterator<RDAElement>(self)
    }

    //MARK: - RangeReplaceableCollection 待实现

}

//MARK: - Equatable

extension RXCDiffArray: Equatable where RDAElement: Equatable {

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
extension RXCDiffArray where RDAElement: DiffAware {

//    public func batch(batchClosure:()->()) {
//        let old:[Element] = [Element].init(self)
//        batchClosure()
//        let new:[Element] = [Element].init(self)
//        let changes = DeepDiff.diff(old: old, new: new)
//        return changes
//    }

}
#endif

public extension RXCDiffArray where RDAElement: RDASectionElementProtocol, RDAElement.RDASectionElementsCollection: RangeReplaceableCollection, RDAElement.RDASectionElementsCollection.Index == Int   {

    typealias SubElement = RDAElement.RDASectionElementsCollection.Element

    //MARK: - 2D C

    @discardableResult
    func add(_ anObject: SubElement, in section:Int)->RDADifference<SubElement> {
        return self.add(contentsOf: [anObject], in: section)
    }

    @discardableResult
    func add(contentsOf objects: [SubElement], in section:Int)->RDADifference<SubElement> {
        return self.insert(contentOf: objects, at: self.count, in: section)
    }

    @discardableResult
    func insert(_ anObject:SubElement, at index:Int,in section:Int)->RDADifference<SubElement> {
        return self.insert(contentOf: [anObject], at: index, in: section)
    }

    @discardableResult
    func insert(contentOf objects:[SubElement], at index:Int, in section:Int)->RDADifference<SubElement> {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        var sectionElement = self[section]
        var elements = sectionElement.rda_elements
        elements.insert(contentsOf: objects, at: index)
        sectionElement.rda_elements = elements
        self.contentArray[section] = sectionElement

        let range:Range<Int> = index..<index+objects.count
        let changes:[RDADifference<SubElement>.Change] = range.map({
            let insert = RDADifference<SubElement>.ElementInsert(item: objects[$0-range.startIndex], index: index, section: section)
            return RDADifference<SubElement>.Change.elementInsert(insert)
        })
        return RDADifference<SubElement>(changes: changes)
    }

    //MARK: - 2D U

    @discardableResult
    func replace(with anObject: SubElement, at index: Int, in section:Int)->RDADifference<SubElement> {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        var sectionElement = self[section]
        var elements = sectionElement.rda_elements
        let old = elements[index]
        elements.replaceSubrange(index..<index+1, with: [anObject])
        sectionElement.rda_elements = elements
        self.contentArray[section] = sectionElement

        let change = RDADifference.Change.elementUpdate(RDADifference.ElementUpdate(oldItem: old, newItem: anObject, index: index, section: section))
        return RDADifference(changes: [change])
    }

    ///re-set the object so we have a chance to send change, drive the UI to refresh
    @discardableResult
    func reload(at index:Int, in section:Int)->RDADifference<SubElement> {
        //send changes directly
        let sectionElement = self[section]
        let element = sectionElement.rda_elements[index]
        let change = RDADifference.Change.elementUpdate(RDADifference.ElementUpdate(oldItem: element, newItem: element, index: index, section: section))
        return RDADifference(changes: [change])
    }

    @discardableResult
    func move(fromIndex:Int,fromSection:Int, toIndex:Int, toSection:Int)->RDADifference<SubElement> {

        guard fromIndex != toIndex && fromSection != toSection else {return RDADifference.empty()}

        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        var fromSectionElement = self[fromSection]
        var fromElements = fromSectionElement.rda_elements
        let fromElement = fromElements[fromIndex]
        var toSectionElement = self[toSection]
        var toElements = toSectionElement.rda_elements

        fromElements.remove(at: fromIndex)
        toElements.insert(fromElement, at: toIndex)
        fromSectionElement.rda_elements = fromElements
        toSectionElement.rda_elements = toElements
        self.contentArray[fromSection] = fromSectionElement
        self.contentArray[toSection] = toSectionElement

        let change = RDADifference.ElementMove(item: fromElement, fromIndex: fromIndex, fromSection: fromSection, toIndex: toIndex, toSection: toSection)
        let changeEnum = RDADifference.Change.elementMove(change)
        return RDADifference(changes: [changeEnum])
    }

    //MARK: - D

    @discardableResult
    func remove(at index: Int, in section:Int)->RDADifference<SubElement> {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        var sectionElement = self[section]
        var elements = sectionElement.rda_elements
        let removed = elements[index]
        elements.remove(at: index)
        sectionElement.rda_elements = elements
        self.contentArray[section] = sectionElement

        let change = RDADifference.ElementDelete(item: removed, index: index, section: section)
        let changeEnum = RDADifference.Change.elementDelete(change)
        return RDADifference(changes: [changeEnum])
    }

    @discardableResult
    func removeAll(in section:Int, where predicate: (SubElement) -> Bool)->RDADifference<SubElement> {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        var changes:[RDADifference<SubElement>.Change] = [RDADifference<SubElement>.Change]()
        var sectionElement = self[section]
        var elements = sectionElement.rda_elements
        for i in elements.enumerated() {
            if predicate(i.element) {
                let change = RDADifference.ElementDelete(item: i.element, index: i.offset, section: section)
                changes.append(RDADifference.Change.elementDelete(change))
            }
        }
        //删除本地数据
        for i in changes.reversed() {
            switch i {
            case .elementDelete(let delete):
                elements.remove(at: delete.index)
            default:
                break
            }
        }
        sectionElement.rda_elements = elements
        self.contentArray[section] = sectionElement

        return RDADifference(changes: changes)
    }

    @discardableResult
    func removeAll(in section:Int)->RDADifference<SubElement> {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        var sectionElement = self[section]
        var elements = sectionElement.rda_elements

        let changes = elements.enumerated().map {(i) -> RDADifference<SubElement>.Change in
            let change = RDADifference.ElementDelete(item: i.element, index: i.offset, section: section)
            return RDADifference.Change.elementDelete(change)
        }

        elements.removeAll()
        sectionElement.rda_elements = elements
        self.contentArray[section] = sectionElement

        return RDADifference(changes: changes)
    }

    subscript(indexPath:IndexPath)->SubElement {
        let sectionElement = self[indexPath.section]
        return sectionElement.rda_elements[indexPath.item]
    }

}

//MARK: - DifferenceKit

#if canImport(DifferenceKit)

//符合一维结构
public extension RXCDiffArray where RDAElement: Differentiable {

//    func batch_differenceKit(batch:()->Void)->RDADifference<RDAElement> {
//        let old = [RDAElement].init(self)
//        batch()
//        let new = [RDAElement].init(self)
//        let dk_changeset = StagedChangeset(source: old, target: new)
//
//    }

    func batch(batch:()->Void) {
        //一维对比
        let old = [RDAElement].init(self)
        batch()
        let new = [RDAElement].init(self)
        let dk_changeset = StagedChangeset(source: old, target: new)
        print(dk_changeset)
        //转化diff结果
        
    }

}

//二维结构
public extension RXCDiffArray where RDAElement: RDASectionElementProtocol, RDAElement: Differentiable, RDAElement.RDASectionElementsCollection.Element: Differentiable {

    func batch(batch:()->Void) {
        //二维对比, 先将数据转换成DiffKit的数据
        let oldSections = self.enumerated().map { (i) -> ArraySection<RDAElement, RDAElement.RDASectionElementsCollection.Element> in
            let section:ArraySection<RDAElement, RDAElement.RDASectionElementsCollection.Element> = ArraySection(model: i.element, elements: i.element.rda_elements)
            return section
        }

        batch()

        let newSections = self.enumerated().map { (i) -> ArraySection<RDAElement, RDAElement.RDASectionElementsCollection.Element> in
            let section:ArraySection<RDAElement, RDAElement.RDASectionElementsCollection.Element> = ArraySection(model: i.element, elements: i.element.rda_elements)
            return section
        }
        let changesets = StagedChangeset(source: oldSections, target: newSections)
        //转换成本类的Change结构
        for changeset in changesets {
            for i in changeset.sectionInserted {

            }
        }
    }

    /*
    /// 进行一维对比, 元素的变化视为 Section 的变化
    func batch_differenceKit_linear(fakeSection:Int=0, batch:()->Void)->RDADifference<RDAElement> {
        let old = [RDAElement].init(self)
        batch()
        let new = [RDAElement].init(self)
        let dk_changeset = StagedChangeset(source: old, target: new, section: fakeSection)

        var mappedChanges:[RDADifference<RDAElement>.Change] = []
        for dk_change in dk_changeset {
            for i in dk_change.elementDeleted {
                let change = RDADifference.SectionDelete(item: old[i.element], index: i.element)
                mappedChanges.append(RDADifference.Change.sectionDelete(change))
            }
            for i in dk_change.elementMoved {
                let change = RDADifference.SectionMove(item: old[i.source.element], fromIndex: i.source.element, toIndex: i.target.element)
                mappedChanges.append(RDADifference.Change.sectionMove(change))
            }
            for i in dk_change.elementUpdated {
                let change = RDADifference.SectionUpdate(oldItem: old[i.element], newItem: new[i.element], index: i.element)

            }


        }

    }
 */

}
#endif

extension RXCDiffArray where RDAElement: RDASectionElementProtocol, RDAElement.RDASectionElementsCollection: MutableCollection {

    func a() {

    }

}
