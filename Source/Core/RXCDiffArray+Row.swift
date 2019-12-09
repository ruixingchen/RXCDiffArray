//
//  RXCDiffArray+Row.swift
//  RXCDiffArray
//
//  Created by ruixingchen on 12/3/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import Foundation

extension RXCDiffArray where Element: RDASectionElementProtocol, Index==Int {

    public typealias RowElement = Any
    public typealias RowIndex = Int

    @discardableResult
    public func addRow(_ newElement: __owned RowElement, in s:Index, userInfo:[AnyHashable:Any]?=nil)->Difference {
        var diff:Difference!
        self.safeWriteExecute(userInfo: userInfo) {
            var sectionElement = self.container[s]
            let count = sectionElement.rda_elements.count
            diff = Difference(changes: CollectionOfOne(Difference.Change.elementInsert(offset: count, section: s)))
            sectionElement.rda_elements.append(newElement)
            self.container.replaceSubrange(s..<s+1, with: CollectionOfOne(sectionElement))
        }
        self.notifyDelegate(diff: [diff], userInfo: userInfo)
        return diff
    }

    @discardableResult
    public func addRow<S>(contentsOf newElements: __owned S, in s:Index, userInfo:[AnyHashable:Any]?=nil)->Difference where S : Collection, S.Element==RowElement {
        var diff:Difference!
        self.safeWriteExecute(userInfo: userInfo) {
            var sectionElement = self.container[s]
            let count = sectionElement.rda_elements.count
            diff = Difference(changes: newElements.enumerated().map({Difference.Change.elementInsert(offset: count+$0.offset, section: s)}))
            sectionElement.rda_elements.append(contentsOf: newElements)
            self.container.replaceSubrange(s..<s+1, with: CollectionOfOne(sectionElement))
        }
        self.notifyDelegate(diff: [diff], userInfo: userInfo)
        return diff
    }

    @discardableResult
    public func insertRow(_ newElement: __owned RowElement, at i: RowIndex, in s:Index, userInfo:[AnyHashable:Any]?=nil)->Difference {
        var diff:Difference!
        self.safeWriteExecute(userInfo: userInfo) {
            diff = Difference(changes: CollectionOfOne(Difference.Change.elementInsert(offset: i, section: s)))
            var sectionElement = self.container[s]
            sectionElement.rda_elements.insert(newElement, at: i)
            self.container.replaceSubrange(s..<s+1, with: CollectionOfOne(sectionElement))
        }
        self.notifyDelegate(diff: [diff], userInfo: userInfo)
        return diff
    }

    @discardableResult
    public func insertRow<C>(contentsOf newElements: __owned C, at i: RowIndex, in s:Index, userInfo:[AnyHashable:Any]?=nil)->Difference where C : Collection,C.Element==RowElement {
        var diff:Difference!
        self.safeWriteExecute(userInfo: userInfo) {
            diff = Difference(changes: newElements.enumerated().map({Difference.Change.elementInsert(offset: i+$0.offset, section: s)}))
            var sectionElement = self.container[s]
            sectionElement.rda_elements.insert(contentsOf: newElements, at: i)
            self.container.replaceSubrange(s..<s+1, with: CollectionOfOne(sectionElement))
        }
        self.notifyDelegate(diff: [diff], userInfo: userInfo)
        return diff
    }

    //MARK: - 二维 更新

    @discardableResult
    public func replaceRow(at position: RowIndex, in s:Index, with newElement: RowElement, userInfo:[AnyHashable:Any]?=nil)->Difference {
        var diff:Difference!
        self.safeWriteExecute(userInfo: userInfo) {
            diff = Difference(changes: CollectionOfOne(Difference.Change.elementUpdate(offset: position, section: s)))
            var sectionElement = self.container[s]
            sectionElement.rda_elements.replaceSubrange(position..<position+1, with: CollectionOfOne(newElement))
            self.container.replaceSubrange(s..<s+1, with: CollectionOfOne(sectionElement))
        }
        self.notifyDelegate(diff: [diff], userInfo: userInfo)
        return diff
    }

    /*
     这个方法复杂度太高, 暂未测试
    @discardableResult
    public func replaceRow<C:Collection, R:RangeExpression>(_ subrange: R, with newElements: __owned C, in s:Index, userInfo:[AnyHashable:Any]?=nil)->Difference where C.Element==RowElement, R.Bound==RowIndex {
        var diff:Difference!
        self.safeWriteExecute(userInfo: userInfo) {
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
            diff = Difference(changes: changes)
        }
        self.notifyDelegate(diff: [diff], userInfo: userInfo)
        return diff
    }
     */

    //MARK: - 二维 删除

    @discardableResult
    public func removeRow(at position: RowIndex, in s:Index,userInfo:[AnyHashable:Any]?=nil) -> Difference {
        var diff:Difference!
        self.safeWriteExecute(userInfo: userInfo) {
            diff = Difference(changes: CollectionOfOne(Difference.Change.elementRemove(offset: position, section: s)))
            var sectionElement = self.container[s]
            sectionElement.rda_elements.remove(at: position)
            self.container.replaceSubrange(s..<s+1, with: CollectionOfOne(sectionElement))
        }
        self.notifyDelegate(diff: [diff], userInfo: userInfo)
        return diff
    }

    @discardableResult
    public func removeRow<R:RangeExpression>(_ bounds: R, in s:Index, userInfo:[AnyHashable:Any]?=nil)->Difference where R.Bound==RowIndex {
        var diff:Difference!
        self.safeWriteExecute(userInfo: userInfo) {
            var sectionElement = self.container[s]
            let realBounds = bounds.relative(to: sectionElement.rda_elements)
            diff = Difference(changes: realBounds.map({Difference.Change.elementRemove(offset: $0, section: s)}))
            sectionElement.rda_elements.removeSubrange(realBounds)
            self.container.replaceSubrange(s..<s+1, with: CollectionOfOne(sectionElement))
        }
        self.notifyDelegate(diff: [diff], userInfo: userInfo)
        return diff
    }

    @discardableResult
    public func removeAllRow(userInfo:[AnyHashable:Any]?=nil, where shouldBeRemoved:@escaping (RowElement, Int) -> Bool)->Difference {
        var diff:Difference!
        self.safeWriteExecute(userInfo: userInfo) {
            let sections = Set<Int>.init((self.container.startIndex..<self.container.endIndex))
            diff = self.removeAllRow(in: sections, userInfo: userInfo, where: shouldBeRemoved)
        }
        return diff
    }

    @discardableResult
    public func removeAllRow(in sections:Swift.Set<Int>, userInfo:[AnyHashable:Any]?=nil, where shouldBeRemoved:@escaping (RowElement, Int) -> Bool)->Difference {
        var diff:Difference!
        self.safeWriteExecute(userInfo: userInfo) {
            var changes:[Difference.Change] = []

            for sectionIndex in sections.sorted(by: <) {
                var sectionElement = self.container[sectionIndex]
                var elements = sectionElement.rda_elements
                if elements.isEmpty {continue}

                var removeIndex:[RowIndex] = []

                for i in elements.enumerated() {
                    if shouldBeRemoved(i.element, i.offset) {
                        removeIndex.append(i.offset)
                    }
                }
                for i in removeIndex.reversed() {
                    elements.remove(at: i)
                }
                if !removeIndex.isEmpty {
                    for i in removeIndex {
                        let change = Difference.Change.elementRemove(offset: i, section: sectionIndex)
                        changes.append(change)
                    }
                    sectionElement.rda_elements = elements
                    self.container.replaceSubrange(sectionIndex..<sectionIndex+1, with: CollectionOfOne(sectionElement))
                }
            }
            //循环完毕
            diff = Difference(changes: changes)
        }
        self.notifyDelegate(diff: [diff], userInfo: userInfo)
        return diff
    }

    //MARK: - 二维 移动

    ///待测试
    @discardableResult
    public func moveRow(fromRow:RowIndex,fromSection:Index, toRow:RowIndex, toSection:Index, userInfo:[AnyHashable:Any]?=nil)->Difference {
        var diff:Difference!
        self.safeWriteExecute(userInfo: userInfo) {
            //这里需要注意同一个Section里面进行移动的场景, 单步执行完毕后需要立刻将section设置回container中
            var _fromSectionElement = self.container[fromSection]
            var _fromElements = _fromSectionElement.rda_elements
            let element = _fromElements.remove(at: fromRow)
            _fromSectionElement.rda_elements = _fromElements
            self.container.replaceSubrange(fromSection..<fromSection+1, with: CollectionOfOne(_fromSectionElement))

            var _toSectionElement = self.container[toSection]
            var _toElements = _toSectionElement.rda_elements
            _toElements.insert(element, at: toRow)
            _toSectionElement.rda_elements = _toElements
            self.container.replaceSubrange(toSection..<toSection+1, with: CollectionOfOne(_toSectionElement))

            let change = Difference.Change.elementMove(fromOffset: fromRow, fromSection: fromSection, toOffset: toRow, toSection: toSection)
            diff = Difference(changes: CollectionOfOne(change))
        }
        self.notifyDelegate(diff: [diff], userInfo: userInfo)
        return diff
    }

}
