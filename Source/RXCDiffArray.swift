//
//  RXCDiffArray.swift
//  RXCDiffArrayExample
//
//  Created by ruixingchen on 7/12/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import Foundation

public protocol SectionElementProtocol {
    
    ///容纳第二维数据的容器类型, 一般是数组类型, Index 最好是Int, 否则很多操作都没法进行
    associatedtype SubElementContainer: RangeReplaceableCollection

    ///这里必须要有setter
    var rda_elements:SubElementContainer {get set}

}

public protocol RXCDiffArrayDelegate: AnyObject {

    func diffArray<SectionContainer: RangeReplaceableCollection>(array:RXCDiffArray<SectionContainer>, didChange difference:RDADifference<SectionContainer.Element,SectionContainer.Element.SubElementContainer.Element>) where SectionContainer.Element: SectionElementProtocol

}

///支持且只支持二维数据结构

///思想涞源 DeepDiff: https://github.com/onmyway133/DeepDiff and DifferenceKit: https://github.com/ra1028/DifferenceKit

/// 范型表示Section的数据的容器类型, 一般是一个Array类型, 如RXCDiffArray<[Card]>, 兼容其他Collection类型
public final class RXCDiffArray<SectionContainer: RangeReplaceableCollection> where SectionContainer.Element: SectionElementProtocol  {
    
    public typealias Element = SectionContainer.Element
    public typealias Index = SectionContainer.Index
    
    public typealias SectionElement = SectionContainer.Element
    public typealias RowElement = SectionContainer.Element.SubElementContainer.Element
    public typealias SectionIndex = SectionContainer.Index
    public typealias RowIndex = SectionContainer.Element.SubElementContainer.Index

    public typealias Difference = RDADifference<SectionElement, RowElement>

    public struct Key {
        ///是否通知代理
        static var notify:String {return "notify"}
    }

    #if (debug || DEBUG)
    public var contentCollection:SectionContainer
    #else
    internal var contentCollection:SectionContainer
    #endif
    
    ///default we are not thread safe
    public var threadSafe:Bool = false

    public weak var delegate:RXCDiffArrayDelegate?

    public init() {
        self.contentCollection = SectionContainer.init()
    }
    
    public init(repeating repeatedValue: Element, count: Int) {
        self.contentCollection = SectionContainer.init(repeating: repeatedValue, count: count)
    }

    public init<S:Sequence>(elements:S) where S.Element==SectionContainer.Element {
        self.contentCollection = SectionContainer.init(elements)
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

    internal func notifyDelegate(diff:RDADifference<SectionElement, RowElement>, userInfo:[AnyHashable:Any]?) {
        if userInfo?[RXCDiffArray.Key.notify] as? Bool ?? true {
            //only false works, anything else is *true*
            self.delegate?.diffArray(array: self, didChange: diff)
        }
    }

    internal func shouldNotify(with userInfo:[AnyHashable:Any]?)->Bool {
        if let b = userInfo?[Key.notify] as? Bool {
            return b
        }
        return true
    }

    ///更新某个Section同时不发出通知, 主要是为了方便操作Element的时候更新数据
    fileprivate func updateSectionWithNoNotify(at position:SectionIndex, newElement: SectionElement) {
        self.contentCollection.replaceSubrange(position..<self.contentCollection.index(position, offsetBy: 1), with: CollectionOfOne(newElement))
    }
    
}

//MARK: - Read

extension RXCDiffArray where SectionContainer.Index==Int, RowIndex==Int {

    public func element(at indexPath:IndexPath)->RowElement? {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        if indexPath.section < 0 || indexPath.section >= self.contentCollection.count {return nil}
        let section = self.contentCollection[indexPath.section]
        if indexPath.item < 0 || indexPath.item >= section.rda_elements.count {return nil}
        return section.rda_elements[indexPath.item]
    }
}

//MARK: - Section 操作

//这里要求Int是为了兼容RDADifference
extension RXCDiffArray where SectionContainer.Index==Int {

    //MARK: - Section 新增

    @discardableResult
    public func rda_appendSection(_ newElement: __owned SectionElement, userInfo:[AnyHashable:Any]?=nil)->Difference {
        return self.rda_appendSection(contentsOf: CollectionOfOne(newElement), userInfo: userInfo)
    }
    
    @discardableResult
    public func rda_appendSection<S: Sequence>(contentsOf newElements: __owned S, userInfo:[AnyHashable:Any]?=nil)->Difference where S.Element==SectionElement {
        let array = [S.Element].init(newElements)
        return self.rda_replaceSection(self.contentCollection.endIndex..<self.contentCollection.endIndex, with: array, userInfo: userInfo)
    }

    @discardableResult
    public func rda_insertSection(_ newElement: __owned SectionElement, at i: SectionIndex, userInfo:[AnyHashable:Any]?=nil)->Difference {
        return self.rda_insertSection(contentsOf: CollectionOfOne(newElement), at: i, userInfo: userInfo)
    }

    @discardableResult
    public func rda_insertSection<C>(contentsOf newElements: __owned C, at i: SectionIndex, userInfo:[AnyHashable:Any]?=nil)->Difference where C : Collection, C.Element==SectionElement {
        return self.rda_replaceSection(i..<i, with: newElements, userInfo: userInfo)
    }

    //MARK: - Section 修改
    
    @discardableResult
    public func rda_replaceSection(at position: SectionIndex, with newElement: SectionElement, userInfo:[AnyHashable:Any]?=nil)->Difference {
        return self.rda_replaceSection(position..<self.contentCollection.index(after: position), with: CollectionOfOne(newElement), userInfo: userInfo)
    }

    @discardableResult
    public func rda_replaceSection<C:Collection, R:RangeExpression>(_ subrange: R, with newElements: __owned C, userInfo:[AnyHashable:Any]?=nil)->Difference where C.Element==RXCDiffArray.Element, R.Bound==SectionContainer.Index {

        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}
        
        ///传入的可能是一个含有无限的范围, 先获取真实的范围
        let realRange:Range<R.Bound> = subrange.relative(to: self.contentCollection)

        ///将range的index转换为新数据的index
        let rangeIndexToNewElementIndex:(_ index:SectionIndex)->C.Index = { (index) in
            let distance = realRange.distance(from: realRange.startIndex, to: index)
            return newElements.index(newElements.startIndex, offsetBy: distance)
        }
        
        var changes:[Difference.Change] = []

        //重合部分的长度
        let publicCount:Int = Swift.min(self.contentCollection.distance(from: realRange.startIndex, to: realRange.endIndex), newElements.distance(from: newElements.startIndex, to: newElements.endIndex))
        if true {
            //重合部分转换成sectionUpdate
            let publicRange = realRange.startIndex..<self.contentCollection.index(realRange.startIndex, offsetBy: publicCount)
            for i:SectionIndex in publicRange {
                //公共部分为替换数据
                let oldElement = self.contentCollection[i]
                let newElement = newElements[rangeIndexToNewElementIndex(i)]
                let change = Difference.Change.sectionUpdate(offset: i, oldElement: oldElement, newElement: newElement)
                changes.append(change)
            }
        }

        if newElements.count != realRange.count {
            let maxLength = Swift.max(self.contentCollection.distance(from: realRange.startIndex, to: realRange.endIndex), newElements.distance(from: newElements.startIndex, to: newElements.endIndex))
            let unevenStart = self.contentCollection.index(realRange.startIndex, offsetBy: publicCount)
            let unevenEnd = realRange.startIndex + maxLength
            let unevenRange:Range<R.Bound> = unevenStart..<unevenEnd

            if newElements.count > realRange.count {
                //新数据的长度大于原始片段长度, 超出的部分视为插入的数据
                // ----
                // ----------
                for i in unevenRange {
                    let newElementIndex = rangeIndexToNewElementIndex(i)
                    let newElement = newElements[newElementIndex]
                    let change = Difference.Change.sectionInsert(offset: i, element: newElement)
                    changes.append(change)
                }
            }else {
                //新数据 < 原始片段, 超出的部分视为删除数据
                // --------
                // ----
                for i in unevenRange {
                    let element = self.contentCollection[i]
                    let change = Difference.Change.sectionRemove(offset: i, element: element)
                    changes.append(change)
                }
            }
        }

        self.contentCollection.replaceSubrange(subrange, with: newElements)
        
        let diff = Difference(changes: changes)
        self.notifyDelegate(diff: diff, userInfo: userInfo)
        return diff
    }

    //MARK: - Section 删除

    public func rda_removeEmptySection() {

    }

    @discardableResult
    public func rda_removeSection(at position: SectionIndex, userInfo:[AnyHashable:Any]?=nil) -> Difference {
        return self.rda_replaceSection(position..<self.contentCollection.index(after: position), with: EmptyCollection(), userInfo: userInfo)
    }
    
    @discardableResult
    public func rda_removeSection(_ bounds: Range<SectionContainer.Index>, userInfo:[AnyHashable:Any]?=nil)->Difference {
        return self.rda_replaceSection(bounds, with: EmptyCollection(), userInfo: userInfo)
    }
    
    ///删除所有符合条件的一维数据
    @discardableResult
    public func rda_removeAllSection(userInfo:[AnyHashable:Any]?=nil, where shouldBeRemoved: (SectionContainer.Element) -> Bool)->Difference {
        
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}
        
        var removedElements:[SectionElement] = []
        var removedIndexs:[SectionIndex] = []

        //从后向前遍历
        for i in (self.contentCollection.startIndex..<self.contentCollection.endIndex).reversed() {
            if shouldBeRemoved(self.contentCollection[i]) {
                //执行删除操作
                let element = self.contentCollection.remove(at: i)
                removedIndexs.append(i)
                removedElements.append(element)
            }
        }

        var changes:[Difference.Change] = []
        if !removedElements.isEmpty {
            for i in (0..<removedElements.count).reversed() {
                let element = removedElements[i]
                let offset = removedIndexs[i]
                changes.append(Difference.Change.sectionRemove(offset: offset, element: element))
            }
        }

        let diff = Difference(changes: changes)
        self.notifyDelegate(diff: diff, userInfo: userInfo)
        return diff
    }

    //MARK: - Section 移动

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

//这里要求Int是为了兼容RDADifference
extension RXCDiffArray where SectionIndex==Int, RowIndex==Int {

    //MARK: - 二维 新增

    @discardableResult
    public func rda_appendRow(_ newElement: __owned RowElement, in s:SectionIndex, userInfo:[AnyHashable:Any]?=nil)->Difference {
        return self.rda_appendRow(contentsOf: CollectionOfOne(newElement), in: s, userInfo: userInfo)
    }

    @discardableResult
    public func rda_appendRow<S>(contentsOf newElements: __owned S, in s:SectionIndex, userInfo:[AnyHashable:Any]?=nil)->Difference where S : Collection, S.Element==RowElement {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        let elements = self.contentCollection[s].rda_elements
        return self.rda_replaceRow(elements.endIndex..<elements.endIndex, with: newElements, in: s, userInfo: userInfo)
    }

    @discardableResult
    public func rda_insertRow(_ newElement: __owned RowElement, at i: RowIndex, in s:SectionIndex, userInfo:[AnyHashable:Any]?=nil)->Difference {
        return self.rda_insertRow(contentsOf: CollectionOfOne(newElement), at: i, in: s, userInfo: userInfo)
    }

    @discardableResult
    public func rda_insertRow<C>(contentsOf newElements: __owned C, at i: RowIndex, in s:SectionIndex, userInfo:[AnyHashable:Any]?=nil)->Difference where C : Collection,C.Element==RowElement {
        return self.rda_replaceRow(i..<i, with: newElements, in: s, userInfo: userInfo)
    }

    //MARK: - 二维 更新

    @discardableResult
    public func rda_replaceRow(at position: RowIndex, in s:SectionIndex, with newElement: RowElement, userInfo:[AnyHashable:Any]?=nil)->Difference {
        let elements = self.contentCollection[s].rda_elements
        return self.rda_replaceRow(position..<elements.index(after: position), with: CollectionOfOne(newElement), in: s, userInfo: userInfo)
    }

    @discardableResult
    public func rda_replaceRow<C:Collection, R:RangeExpression>(_ subrange: R, with newElements: __owned C, in s:SectionIndex, userInfo:[AnyHashable:Any]?=nil)->Difference where C.Element==RXCDiffArray.RowElement, R.Bound==RowIndex {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        var section = self.contentCollection[s]
        var elements = section.rda_elements

        ///传入的可能是一个含有无限的范围, 先获取真实的范围
        let realRange:Range<R.Bound> = subrange.relative(to: elements)

        ///将range的index转换为新数据的index
        let rangeIndexToNewElementIndex:(_ index:SectionIndex)->C.Index = { (index) in
            let distance = realRange.distance(from: realRange.startIndex, to: index)
            return newElements.index(newElements.startIndex, offsetBy: distance)
        }

        var changes:[Difference.Change] = []

        //重合部分我们认为是更新数据, 之后的部分认为是删除或者新增数据

        //重合部分的长度
        let publicCount:Int = Swift.min(realRange.distance(from: realRange.startIndex, to: realRange.endIndex), newElements.distance(from: newElements.startIndex, to: newElements.endIndex))
        if true {
            //将重合的部分转换成elementUpdate
            let publicRange = realRange.startIndex..<realRange.index(realRange.startIndex, offsetBy: publicCount)
            for i:SectionIndex in publicRange {
                //公共部分为替换数据
                let oldElement = elements[i]
                let indexForNewElement = rangeIndexToNewElementIndex(i)
                let newElement = newElements[indexForNewElement]
                let change = Difference.Change.elementUpdate(offset: i, section: s, oldElement: oldElement, newElement: newElement)
                changes.append(change)
            }
        }

        if newElements.count != realRange.count {
            let maxLength = Swift.max(elements.distance(from: realRange.startIndex, to: realRange.endIndex), newElements.distance(from: newElements.startIndex, to: newElements.endIndex))
            let unevenStart = elements.index(realRange.startIndex, offsetBy: publicCount)
            let unevenEnd = realRange.startIndex + maxLength
            let unevenRange:Range<R.Bound> = unevenStart..<unevenEnd

            if newElements.count > realRange.count {
                //新数据的长度大于原始片段长度, 超出的部分视为插入的数据
                // ----
                // ----------
                for i in unevenRange {
                    let newElementIndex = rangeIndexToNewElementIndex(i)
                    let newElement = newElements[newElementIndex]
                    let change = Difference.Change.elementInsert(offset: i, section: s, element: newElement)
                    changes.append(change)
                }
            }else {
                //新数据 < 原始片段, 超出的部分视为删除数据
                // --------
                // ----
                for i in unevenRange {
                    let element = elements[i]
                    let change = Difference.Change.elementRemove(offset: i, section: s, element: element)
                    changes.append(change)
                }
            }
        }

        elements.replaceSubrange(subrange, with: newElements)
        section.rda_elements = elements
        self.updateSectionWithNoNotify(at: s, newElement: section)

        let diff = Difference(changes: changes)
        self.notifyDelegate(diff: diff, userInfo: userInfo)
        return diff
    }

    //MARK: - 二维 删除

    @discardableResult
    public func rda_removeRow(at position: RowIndex, in s:SectionIndex,userInfo:[AnyHashable:Any]?=nil) -> Difference {
        let elements = self.contentCollection[s].rda_elements
        return self.rda_replaceRow(position..<elements.index(after: position), with: EmptyCollection(), in: s, userInfo: userInfo)
    }

    @discardableResult
    public func rda_removeRow<R:RangeExpression>(_ bounds: R, in s:SectionIndex, userInfo:[AnyHashable:Any]?=nil)->Difference where R.Bound==RowIndex {
        return self.rda_replaceRow(bounds, with: EmptyCollection(), in: s, userInfo: userInfo)
    }

    @discardableResult
    public func rda_removeAllRow(userInfo:[AnyHashable:Any]?=nil, where shouldBeRemoved: (RowElement) -> Bool)->Difference {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}
        return self.rda_removeAllRow(in: self.contentCollection.startIndex..<self.contentCollection.endIndex, userInfo: userInfo, where: shouldBeRemoved)
    }

    @discardableResult
    public func rda_removeAllRow<R:RangeExpression>(in range:R, userInfo:[AnyHashable:Any]?=nil, where shouldBeRemoved: (RowElement) -> Bool)->Difference where R.Bound==SectionIndex{
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        let realRange = range.relative(to: self.contentCollection)
        let slice:SectionContainer.SubSequence = self.contentCollection[realRange]
        var changes:[Difference.Change] = []

        for sectionEnum in slice.enumerated() {
            var section = sectionEnum.element
            let sectionIndex = self.contentCollection.index(realRange.startIndex, offsetBy: sectionEnum.offset)
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
            //生成Change
            for i in (0..<removeIndex.count).reversed() {
                let change = Difference.Change.elementRemove(offset: removeIndex[i], section: sectionIndex, element: removeElement[i])
                changes.append(change)
            }

            section.rda_elements = elements
            self.updateSectionWithNoNotify(at: sectionIndex, newElement: section)
        }

        let diff = Difference(changes: changes)
        self.notifyDelegate(diff: diff, userInfo: userInfo)
        return diff
    }

    //MARK: - 二维 移动

    ///待测试
    @discardableResult
    public func rda_moveRow(fromRow:RowIndex,fromSection:SectionIndex, toRow:RowIndex, toSection:SectionIndex, userInfo:[AnyHashable:Any]?=nil)->Difference {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        //这里需要注意同一个Section里面进行移动的场景, 单步执行完毕后需要立刻将section设置回contentCollection中
        var _fromSection = self.contentCollection[fromSection]
        let element = _fromSection.rda_elements.remove(at: fromRow)
        self.updateSectionWithNoNotify(at: fromSection, newElement: _fromSection)
        var _toSection = self.contentCollection[toSection]
        _toSection.rda_elements.insert(element, at: toRow)
        self.updateSectionWithNoNotify(at: toSection, newElement: _toSection)

        let change = Difference.Change.elementMove(fromOffset: fromRow, fromSection: fromSection, toOffset: toRow, toSection: toSection, element: element)

        let diff = Difference(changes: CollectionOfOne(change))
        self.notifyDelegate(diff: diff, userInfo: userInfo)
        return diff
    }
    
}

//MARK: - Collection
extension RXCDiffArray: Collection {

    public var startIndex: SectionContainer.Index {return self.contentCollection.startIndex}

    public var endIndex: SectionContainer.Index {return self.contentCollection.endIndex}

    public subscript(position: SectionContainer.Index) -> SectionContainer.Element {
        get {return self.contentCollection[position]}
    }

    public func index(after i: SectionContainer.Index) -> SectionContainer.Index {
        return self.contentCollection.index(after: i)
    }

    public var underestimatedCount: Int {return self.contentCollection.underestimatedCount}

}

#if canImport(DifferenceKit)
import DifferenceKit

extension RXCDiffArray where SectionElement: Differentiable, RowElement:Differentiable {

    ///进行批量处理后使用 DifferenceKit 计算差异, 返回计算结果
    ///返回的结果是一个数组, 且后一个数组的数据是依赖于前一个数组的, 将前一个数组的改变映射到UI上后才可以进行下一个数组的映射
    ///注意在修改的同时需要传入userInfo, 让batch期间的操作不要通知代理
    func batchWithDifferenceKit(batch:()->Void)->[Difference] {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        let oldElements = self.contentCollection.map {
            return ArraySection(model: $0, elements: $0.rda_elements)
        }
        batch()
        let newElements = self.contentCollection.map {
            return ArraySection(model: $0, elements: $0.rda_elements)
        }

        let dk_diff = StagedChangeset(source: oldElements, target: newElements)
        var differences:[Difference] = []
        for i in dk_diff {
            var changes:[Difference.Change] = []

            if !i.sectionDeleted.isEmpty {
                let _changes = i.sectionDeleted.map { (section) -> Difference.Change in
                    return Difference.Change.sectionRemove(offset: section, element: nil)
                }
                changes.append(contentsOf: _changes)
            }
            if !i.sectionInserted.isEmpty {
                let _changes = i.sectionInserted.map { (section) -> Difference.Change in
                    return Difference.Change.sectionInsert(offset: section, element: nil)
                }
                changes.append(contentsOf: _changes)
            }
            if !i.sectionUpdated.isEmpty {
                let _changes = i.sectionUpdated.map { (section) -> Difference.Change in
                    return Difference.Change.sectionUpdate(offset: section, oldElement: nil, newElement: nil)
                }
                changes.append(contentsOf: _changes)
            }
            if !i.sectionMoved.isEmpty {
                let _changes = i.sectionMoved.map { (section) -> Difference.Change in
                    return Difference.Change.sectionMove(fromOffset: section.source, toOffset: section.target, element: nil)
                }
                changes.append(contentsOf: _changes)
            }

            if !i.elementDeleted.isEmpty {
                let _changes = i.elementDeleted.map { (path) -> Difference.Change in
                    return Difference.Change.elementRemove(offset: path.element, section: path.section, element: nil)
                }
                changes.append(contentsOf: _changes)
            }
            if !i.elementInserted.isEmpty {
                let _changes = i.elementInserted.map { (path) -> Difference.Change in
                    return Difference.Change.elementInsert(offset: path.element, section: path.section, element: nil)
                }
                changes.append(contentsOf: _changes)
            }
            if !i.elementUpdated.isEmpty {
                let _changes = i.elementUpdated.map { (path) -> Difference.Change in
                    return Difference.Change.elementUpdate(offset: path.element, section: path.section, oldElement: nil, newElement: nil)
                }
                changes.append(contentsOf: _changes)
            }
            if !i.elementMoved.isEmpty {
                let _changes = i.elementMoved.map { (path) -> Difference.Change in
                    return Difference.Change.elementMove(fromOffset: path.source.element, fromSection: path.source.section, toOffset: path.target.element, toSection: path.target.section, element: nil)
                }
                changes.append(contentsOf: _changes)
            }
            let diff = Difference(changes: changes)
            differences.append(diff)
        }
        return differences
    }

}
#endif
