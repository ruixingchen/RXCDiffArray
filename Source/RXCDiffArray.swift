//
//  RXCDiffArray.swift
//  RXCDiffArray
//
//  Created by ruixingchen on 10/30/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import Foundation

///描述一个具有二维元素的容器
///describe a 2D element container
public protocol RDASectionElementProtocol {

    var rda_elements:[Any] {get set}

}

///the delegate
public protocol RXCDiffArrayDelegate: AnyObject {

    func diffArray<ElementContainer: RangeReplaceableCollection>(diffArray:RXCDiffArray<ElementContainer>, didModifiedWith differences:[RDADifference<ElementContainer>])

}

public final class RXCDiffArray<ElementContainer: RangeReplaceableCollection>: Collection {

    public typealias Element = ElementContainer.Element
    public typealias Index = ElementContainer.Index
    public typealias Difference = RDADifference<ElementContainer>

    public var threadSafe:Bool = true

    internal fileprivate(set) var container:ElementContainer = ElementContainer.init()

    internal let delegates:NSHashTable<AnyObject> = NSHashTable.weakObjects()

    public init() {
        self.container = ElementContainer.init()
    }

    public init(repeating repeatedValue: Element, count: Int) {
        self.container = ElementContainer.init(repeating: repeatedValue, count: count)
    }

    public init<S:Sequence>(elements:S) where S.Element==ElementContainer.Element {
        self.container = ElementContainer.init(elements)
    }

    //MARK: - Collection Property

    public var count: Int {return self.container.count}
    public var underestimatedCount: Int {return self.container.underestimatedCount}
    public var isEmpty: Bool {return self.container.isEmpty}
    public func index(after i: ElementContainer.Index) -> ElementContainer.Index {
        return self.container.index(after: i)
    }
    public var startIndex: ElementContainer.Index {return self.container.startIndex}
    public var endIndex: ElementContainer.Index {return self.container.endIndex}

    public subscript(position: ElementContainer.Index) -> ElementContainer.Element {
        return self.container[position]
    }

    //MARK: - Tool

    internal func lockContainer() {
        ///should lock the container but just lock self just works fine, ha~😂
        objc_sync_enter(self)
    }

    internal func unlockContainer() {
        objc_sync_exit(self)
    }

    public func addDelegate(_ delegate:RXCDiffArrayDelegate) {
        guard !self.delegates.contains(delegate as AnyObject) else {return}
        self.delegates.add(delegate)
    }

    public func removeDelegate(_ delegate:RXCDiffArrayDelegate) {
        self.delegates.remove(delegate)
    }

    internal func notifyDelegate(diff:[Difference], userInfo:[AnyHashable:Any]?) {
        if (userInfo?["notify"] as? Bool ?? true) {
            for i in self.delegates.allObjects {
                if let delegate = i as? RXCDiffArrayDelegate {
                    delegate.diffArray(diffArray: self, didModifiedWith: diff)
                }
            }
        }
    }

    ///convert to a swift array
    public func toArray()->[Element] {
        return self.container.map({$0})
    }

}

//MARK: - Section
extension RXCDiffArray where Index==Int {

    @discardableResult
    public func add(_ newElement: __owned Element, userInfo:[AnyHashable:Any]?=nil)->Difference {
        return self.add(contentsOf: CollectionOfOne(newElement), userInfo: userInfo)
    }

    @discardableResult
    public func add<S: Sequence>(contentsOf newElements: __owned S, userInfo:[AnyHashable:Any]?=nil)->Difference where S.Element==Element {
        let array = [S.Element].init(newElements)
        return self.replace(self.container.endIndex..<self.container.endIndex, with: array, userInfo: userInfo)
    }

    @discardableResult
    public func insert(_ newElement: __owned Element, at i: Index, userInfo:[AnyHashable:Any]?=nil)->Difference {
        return self.insert(contentsOf: CollectionOfOne(newElement), at: i, userInfo: userInfo)
    }

    @discardableResult
    public func insert<C>(contentsOf newElements: __owned C, at i: Index, userInfo:[AnyHashable:Any]?=nil)->Difference where C : Collection, C.Element==Element {
        return self.replace(i..<i, with: newElements, userInfo: userInfo)
    }

    //MARK: - Section 修改

    @discardableResult
    public func replace(at position: Index, with newElement: Element, userInfo:[AnyHashable:Any]?=nil)->Difference {
        return self.replace(position..<self.container.index(after: position), with: CollectionOfOne(newElement), userInfo: userInfo)
    }

    @discardableResult
    public func replace<C:Collection, R:RangeExpression>(_ subrange: R, with newElements: __owned C, userInfo:[AnyHashable:Any]?=nil)->Difference where C.Element==Element, R.Bound==Index {

        //逻辑: 判断新数据和要替换的范围的长度, 两个部分数据重合的部分视为数据的更新, 新数据比替换范围长的部分视为数据插入, 新数据比替换范围短的被删除的部分视为删除数据

        let safe:Bool = self.threadSafe
        if safe {self.lockContainer()}
        defer {if safe {self.unlockContainer()}}

        ///传入的替换范围可能是一个含有无限的范围, 将这个范围转换成真实有效的范围
        let realSubrange:Range<R.Bound> = subrange.relative(to: self.container)

        ///这个closure可以将当前数据的index转换为新数据的index
//        let rangeIndexToNewElementIndex:(_ index:Index)->C.Index = { (index) in
//            let distance = realSubrange.distance(from: realSubrange.startIndex, to: index)
//            return newElements.index(newElements.startIndex, offsetBy: distance)
//        }

        var changes:[Difference.Change] = []

        //重合部分的长度
        let newElementCount = newElements.distance(from: newElements.startIndex, to: newElements.endIndex)
        let subrangeLength = self.container.distance(from: realSubrange.startIndex, to: realSubrange.endIndex)
        let publicCount:Int = Swift.min(newElementCount, subrangeLength)
        if true {
            //重合部分转换成sectionUpdate
            let publicRange = realSubrange.startIndex..<self.container.index(realSubrange.startIndex, offsetBy: publicCount)
            for i:Index in publicRange {
                //公共部分为替换数据
                //let oldElement = self.container[i]
                //let newElement = newElements[rangeIndexToNewElementIndex(i)]
                //                let elementChange = Difference.Change
                let change = Difference.Change.sectionUpdate(offset: i)
                changes.append(change)
            }
        }

        if newElements.count != realSubrange.count {
            let maxLength = Swift.max(subrangeLength, newElementCount)
            let unevenStart = self.container.index(realSubrange.startIndex, offsetBy: publicCount)
            let unevenEnd = realSubrange.startIndex + maxLength
            let unevenRange:Range<R.Bound> = unevenStart..<unevenEnd

            if newElements.count > realSubrange.count {
                //新数据的长度大于原始片段长度, 超出的部分视为插入的数据
                // ----
                // ----------
                for i in unevenRange {
                    //let newElementIndex = rangeIndexToNewElementIndex(i)
                    //let newElement = newElements[newElementIndex]
                    let change = Difference.Change.sectionInsert(offset: i)
                    changes.append(change)
                }
            }else {
                //新数据 < 原始片段, 超出的部分视为删除数据
                // --------
                // ----
                for i in unevenRange {
                    //let element = self.container[i]
                    let change = Difference.Change.sectionRemove(offset: i)
                    changes.append(change)
                }
            }
        }

        self.container.replaceSubrange(subrange, with: newElements)

        let diff = Difference(changes: changes)
        self.notifyDelegate(diff: [diff], userInfo: userInfo)
        return diff
    }

    @discardableResult
    public func remove(at position: Index, userInfo:[AnyHashable:Any]?=nil) -> Difference {
        return self.replace(position..<self.container.index(after: position), with: EmptyCollection(), userInfo: userInfo)
    }

    @discardableResult
    public func remove(_ bounds: Range<Index>, userInfo:[AnyHashable:Any]?=nil)->Difference {
        return self.replace(bounds, with: EmptyCollection(), userInfo: userInfo)
    }

    @discardableResult
    public func removeAll(userInfo:[AnyHashable:Any]?=nil, where shouldBeRemoved: (Element) -> Bool)->Difference {

        let safe:Bool = self.threadSafe
        if safe {self.lockContainer()}
        defer {if safe {self.unlockContainer()}}

        var removeElements:[ElementContainer.Element] = []
        var removeIndexs:[ElementContainer.Index] = []

        //从后向前遍历
        for i in (self.container.startIndex..<self.container.endIndex).reversed() {
            if shouldBeRemoved(self.container[i]) {
                //执行删除操作
                let element = self.container.remove(at: i)
                removeIndexs.append(i)
                removeElements.append(element)
            }
        }

        var changes:[Difference.Change] = []
        if !removeElements.isEmpty {
            for i in (0..<removeElements.count).reversed() {
                //let element = removedElements[i]
                let offset = removeIndexs[i]
                changes.append(Difference.Change.sectionRemove(offset: offset))
            }
        }

        let diff = Difference(changes: changes)
        self.notifyDelegate(diff: [diff], userInfo: userInfo)
        return diff
    }

    //MARK: - Section 移动

    ///移动Section
    @discardableResult
    public func move(from position:Index, to toPosition:Index,userInfo:[AnyHashable:Any]?=nil)->Difference {
        let safe:Bool = self.threadSafe
        if safe {self.lockContainer()}
        defer {if safe {self.lockContainer()}}

        let element = self.container.remove(at: position)
        self.container.insert(element, at: toPosition)

        let change = Difference.Change.sectionMove(fromOffset: position, toOffset: toPosition)
        let diff = Difference(changes: CollectionOfOne(change))
        self.notifyDelegate(diff: [diff], userInfo: userInfo)
        return diff
    }

}

//MARK: - Element
extension RXCDiffArray where Element: RDASectionElementProtocol, Index==Int {

    public typealias RowElement = Any
    public typealias RowIndex = Int

    @discardableResult
    public func addRow(_ newElement: __owned RowElement, in s:Index, userInfo:[AnyHashable:Any]?=nil)->Difference {
        return self.addRow(contentsOf: CollectionOfOne(newElement), in: s, userInfo: userInfo)
    }

    @discardableResult
    public func addRow<S>(contentsOf newElements: __owned S, in s:Index, userInfo:[AnyHashable:Any]?=nil)->Difference where S : Collection, S.Element==RowElement {
        let safe:Bool = self.threadSafe
        if safe {self.lockContainer()}
        defer {if safe {self.unlockContainer()}}

        let elements = self.container[s].rda_elements
        return self.replaceRow(elements.endIndex..<elements.endIndex, with: newElements, in: s, userInfo: userInfo)
    }

    @discardableResult
    public func insertRow(_ newElement: __owned RowElement, at i: RowIndex, in s:Index, userInfo:[AnyHashable:Any]?=nil)->Difference {
        return self.insertRow(contentsOf: CollectionOfOne(newElement), at: i, in: s, userInfo: userInfo)
    }

    @discardableResult
    public func insertRow<C>(contentsOf newElements: __owned C, at i: RowIndex, in s:Index, userInfo:[AnyHashable:Any]?=nil)->Difference where C : Collection,C.Element==RowElement {
        return self.replaceRow(i..<i, with: newElements, in: s, userInfo: userInfo)
    }

    //MARK: - 二维 更新

    @discardableResult
    public func replaceRow(at position: RowIndex, in s:Index, with newElement: RowElement, userInfo:[AnyHashable:Any]?=nil)->Difference {
        let elements = self.container[s].rda_elements
        return self.replaceRow(position..<elements.index(after: position), with: CollectionOfOne(newElement), in: s, userInfo: userInfo)
    }

    @discardableResult
    public func replaceRow<C:Collection, R:RangeExpression>(_ subrange: R, with newElements: __owned C, in s:Index, userInfo:[AnyHashable:Any]?=nil)->Difference where C.Element==RowElement, R.Bound==RowIndex {
        let safe:Bool = self.threadSafe
        if safe {self.lockContainer()}
        defer {if safe {self.unlockContainer()}}

        var section = self.container[s]
        var elements = section.rda_elements

        ///传入的可能是一个含有无限的范围, 先获取真实的范围
        let realSubrange:Range<R.Bound> = subrange.relative(to: elements)

        ///将range的index转换为新数据的index
//        let rangeIndexToNewElementIndex:(_ index:Index)->C.Index = { (index) in
//            let distance = realSubrange.distance(from: realSubrange.startIndex, to: index)
//            return newElements.index(newElements.startIndex, offsetBy: distance)
//        }

        var changes:[Difference.Change] = []

        //重合部分我们认为是更新数据, 之后的部分认为是删除或者新增数据

        //重合部分的长度
        let publicCount:Int = Swift.min(realSubrange.distance(from: realSubrange.startIndex, to: realSubrange.endIndex), newElements.distance(from: newElements.startIndex, to: newElements.endIndex))
        if publicCount > 0 {
            //将重合的部分转换成elementUpdate
            let publicRange = realSubrange.startIndex..<realSubrange.index(realSubrange.startIndex, offsetBy: publicCount)
            for i:Index in publicRange {
                //公共部分为替换数据
//                let oldElement = elements[i] as? RowElement
//                let indexForNewElement = rangeIndexToNewElementIndex(i)
//                let newElement = newElements[indexForNewElement]
                let change = Difference.Change.elementUpdate(offset: i, section: s)
                changes.append(change)
            }
        }

        if newElements.count != realSubrange.count {
            let maxLength = Swift.max(elements.distance(from: realSubrange.startIndex, to: realSubrange.endIndex), newElements.distance(from: newElements.startIndex, to: newElements.endIndex))
            let unevenStart = elements.index(realSubrange.startIndex, offsetBy: publicCount)
            let unevenEnd = realSubrange.startIndex + maxLength
            let unevenRange:Range<R.Bound> = unevenStart..<unevenEnd

            if newElements.count > realSubrange.count {
                //新数据的长度大于原始片段长度, 超出的部分视为插入的数据
                // ----
                // ----------
                for i in unevenRange {
//                    let newElementIndex = rangeIndexToNewElementIndex(i)
//                    let newElement = newElements[newElementIndex]
                    let change = Difference.Change.elementInsert(offset: i, section: s)
                    changes.append(change)
                }
            }else {
                //新数据 < 原始片段, 超出的部分视为删除数据
                // --------
                // ----
                for i in unevenRange {
//                    let element = elements[i] as! RowElement
                    let change = Difference.Change.elementRemove(offset: i, section: s)
                    changes.append(change)
                }
            }
        }
        elements.replaceSubrange(subrange, with: newElements.map({$0 as Any}))
        section.rda_elements = elements
        self.container.replaceSubrange(s..<self.container.index(after: s), with: CollectionOfOne(section))
        let diff = Difference(changes: changes)
        self.notifyDelegate(diff: [diff], userInfo: userInfo)
        return diff
    }

    //MARK: - 二维 删除

    @discardableResult
    public func removeRow(at position: RowIndex, in s:Index,userInfo:[AnyHashable:Any]?=nil) -> Difference {
        let elements = self.container[s].rda_elements
        return self.replaceRow(position..<elements.index(after: position), with: EmptyCollection(), in: s, userInfo: userInfo)
    }

    @discardableResult
    public func removeRow<R:RangeExpression>(_ bounds: R, in s:Index, userInfo:[AnyHashable:Any]?=nil)->Difference where R.Bound==RowIndex {
        return self.replaceRow(bounds, with: EmptyCollection(), in: s, userInfo: userInfo)
    }

    @discardableResult
    public func removeAllRow(userInfo:[AnyHashable:Any]?=nil, where shouldBeRemoved: (RowElement) -> Bool)->Difference {
        let safe:Bool = self.threadSafe
        if safe {self.lockContainer()}
        defer {if safe {self.unlockContainer()}}
        return self.removeAllRow(in: self.container.startIndex..<self.container.endIndex, userInfo: userInfo, where: shouldBeRemoved)
    }

    @discardableResult
    public func removeAllRow<R:RangeExpression>(in range:R, userInfo:[AnyHashable:Any]?=nil, where shouldBeRemoved: (RowElement) -> Bool)->Difference where R.Bound==Index{
        let safe:Bool = self.threadSafe
        if safe {self.lockContainer()}
        defer {if safe {self.unlockContainer()}}

        var changes:[Difference.Change] = []

        for sectionIndex in range.relative(to: self.container) {
            var section = self.container[sectionIndex]
            var elements = section.rda_elements

            if elements.isEmpty {continue}

            var removeIndex:[RowIndex] = []
            var removeElement:[RowElement] = []

            for rowIndex in (elements.startIndex..<elements.endIndex).reversed() {
                if shouldBeRemoved(elements[rowIndex]) {
                    removeIndex.append(rowIndex)
                    //在这里执行删除元素的操作
                    removeElement.append(elements.remove(at: rowIndex))
                }
            }

            if !removeIndex.isEmpty {
                //生成Change
                for i in (0..<removeIndex.count).reversed() {
                    //let removedRowElement = removeElement[i]
                    let change = Difference.Change.elementRemove(offset: removeIndex[i], section: sectionIndex)
                    changes.append(change)
                }

                section.rda_elements = elements
                self.container.replaceSubrange(sectionIndex..<self.container.index(after: sectionIndex), with: CollectionOfOne(section))
            }
        }

        let diff = Difference(changes: changes)
        self.notifyDelegate(diff: [diff], userInfo: userInfo)
        return diff
    }

    //MARK: - 二维 移动

    ///待测试
    @discardableResult
    public func moveRow(fromRow:RowIndex,fromSection:Index, toRow:RowIndex, toSection:Index, userInfo:[AnyHashable:Any]?=nil)->Difference {
        let safe:Bool = self.threadSafe
        if safe {self.lockContainer()}
        defer {if safe {self.unlockContainer()}}

        //这里需要注意同一个Section里面进行移动的场景, 单步执行完毕后需要立刻将section设置回container中
        var _fromSection = self.container[fromSection]
        var _fromElements = _fromSection.rda_elements
        let element = _fromElements.remove(at: fromRow)
        _fromSection.rda_elements = _fromElements
        self.container.replaceSubrange(fromSection..<self.container.index(after: fromSection), with: CollectionOfOne(_fromSection))

        var _toSection = self.container[toSection]
        var _toElements = _toSection.rda_elements
        _toElements.insert(element, at: toRow)
        _toSection.rda_elements = _toElements
        self.container.replaceSubrange(toSection..<self.container.index(after: toSection), with: CollectionOfOne(_toSection))

        let change = Difference.Change.elementMove(fromOffset: fromRow, fromSection: fromSection, toOffset: toRow, toSection: toSection)
        let diff = Difference(changes: CollectionOfOne(change))
        self.notifyDelegate(diff: [diff], userInfo: userInfo)
        return diff
    }

}
