//
//  RXCDiffArray+Section.swift
//  RXCDiffArray
//
//  Created by ruixingchen on 12/3/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import Foundation

extension RXCDiffArray where Index==Int {

    @discardableResult
    public func add(_ newElement: __owned Element, userInfo:[AnyHashable:Any]?=nil)->Difference {
        var diff:Difference!
        self.safeWriteExecute(userInfo: userInfo) {
            let count = self.container.count
            diff = Difference.init(changes: CollectionOfOne(Difference.Change.sectionInsert(offset: count)))
            self.container.append(newElement)
        }
        self.notifyDelegate(diff: [diff], userInfo: userInfo)
        return diff
    }

    @discardableResult
    public func add<S: Sequence>(contentsOf newElements: __owned S, userInfo:[AnyHashable:Any]?=nil)->Difference where S.Element==Element {
        var diff:Difference!
        self.safeWriteExecute(userInfo: userInfo) {
            let count = self.container.count
            diff = Difference(changes: newElements.enumerated().map({Difference.Change.sectionInsert(offset: count + $0.offset)}))
            self.container.append(contentsOf: newElements)
        }
        self.notifyDelegate(diff: [diff], userInfo: userInfo)
        return diff
    }

    @discardableResult
    public func insert(_ newElement: __owned Element, at i: Index, userInfo:[AnyHashable:Any]?=nil)->Difference {
        var diff:Difference!
        self.safeWriteExecute(userInfo: userInfo) {
            diff = Difference(changes: CollectionOfOne(Difference.Change.sectionInsert(offset: i)))
            self.container.insert(newElement, at: i)
        }
        self.notifyDelegate(diff: [diff], userInfo: userInfo)
        return diff
    }

    @discardableResult
    public func insert<C>(contentsOf newElements: __owned C, at i: Index, userInfo:[AnyHashable:Any]?=nil)->Difference where C : Collection, C.Element==Element {
        var diff:Difference!
        self.safeWriteExecute(userInfo: userInfo) {
            diff = Difference(changes: newElements.enumerated().map({Difference.Change.sectionInsert(offset: i + $0.offset)}))
            self.container.insert(contentsOf: newElements, at: i)
        }
        self.notifyDelegate(diff: [diff], userInfo: userInfo)
        return diff
    }

    //MARK: - Section 修改

    @discardableResult
    public func replace(at position: Index, with newElement: Element, userInfo:[AnyHashable:Any]?=nil)->Difference {
        var diff:Difference!
        self.safeWriteExecute(userInfo: userInfo) {
            diff = Difference(changes: CollectionOfOne(Difference.Change.sectionUpdate(offset: position)))
            self.container.replaceSubrange(position..<position+1, with: CollectionOfOne(newElement))
        }
        self.notifyDelegate(diff: [diff], userInfo: userInfo)
        return diff
    }

    /*
    这个方法复杂度太高了, 也不太好测试, 暂时先禁用
    @discardableResult
    public func replace<C:Collection, R:RangeExpression>(_ subrange: R, with newElements: __owned C, userInfo:[AnyHashable:Any]?=nil)->Difference where C.Element==Element, R.Bound==Index {

        //逻辑: 判断新数据和要替换的范围的长度, 两个部分数据重合的部分视为数据的更新, 新数据比替换范围长的部分视为数据插入, 新数据比替换范围短的被删除的部分视为删除数据
        var diff:Difference!
        self.safeWriteExecute(userInfo: userInfo) {
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

            let __diff = Difference(changes: changes)
            diff = __diff
        }
        self.notifyDelegate(diff: [diff], userInfo: userInfo)
        return diff
    }
     */

    @discardableResult
    public func remove(at position: Index, userInfo:[AnyHashable:Any]?=nil) -> Difference {
        var diff:Difference!
        self.safeWriteExecute(userInfo: userInfo) {
            diff = Difference(changes: CollectionOfOne(Difference.Change.sectionRemove(offset: position)))
            self.container.remove(at: position)
        }
        self.notifyDelegate(diff: [diff], userInfo: userInfo)
        return diff
    }

    @discardableResult
    public func remove(_ bounds: Range<Index>, userInfo:[AnyHashable:Any]?=nil)->Difference {
        var diff:Difference!
        self.safeWriteExecute(userInfo: userInfo) {
            let realBounds = bounds.relative(to: self)
            diff = Difference(changes: realBounds.map({Difference.Change.sectionRemove(offset: $0)}))
            self.container.removeSubrange(bounds)
        }
        self.notifyDelegate(diff: [diff], userInfo: userInfo)
        return diff
    }

    @discardableResult
    public func removeAll(userInfo:[AnyHashable:Any]?=nil, where shouldBeRemoved:@escaping (Element) -> Bool)->Difference {
        var diff:Difference!
        self.safeWriteExecute(userInfo: userInfo) {
            var removeElements:[ElementContainer.Element] = []
            var removeIndexs:[ElementContainer.Index] = []

            //先遍历找出需要删除的index
            for i in self.enumerated() {
                if shouldBeRemoved(i.element) {
                    removeIndexs.append(i.offset)
                    removeElements.append(self.container[i.offset])
                }
            }
            //开始删除数据
            //注意reversed
            for i in removeIndexs.reversed() {
                self.container.remove(at: i)
            }
            //生成Diff
            var changes:[Difference.Change] = []
            if !removeIndexs.isEmpty {
                for i in removeIndexs {
                    changes.append(Difference.Change.sectionRemove(offset: i))
                }
            }
            diff = Difference(changes: changes)
        }
        self.notifyDelegate(diff: [diff], userInfo: userInfo)
        return diff
    }

    //MARK: - Section 移动

    ///移动Section
    @discardableResult
    public func move(from position:Index, to toPosition:Index,userInfo:[AnyHashable:Any]?=nil)->Difference {
        var diff:Difference!
        self.safeWriteExecute(userInfo: userInfo) {
            let element = self.container.remove(at: position)
            self.container.insert(element, at: toPosition)

            let change = Difference.Change.sectionMove(fromOffset: position, toOffset: toPosition)
            diff = Difference(changes: CollectionOfOne(change))
        }
        self.notifyDelegate(diff: [diff], userInfo: userInfo)
        return diff
    }

}
