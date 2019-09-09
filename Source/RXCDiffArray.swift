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

//对一维结构, 数据的操作默认是Section操作

///an array that can return changes, idea from DeepDiff: https://github.com/onmyway133/DeepDiff and DifferenceKit: https://github.com/ra1028/DifferenceKit
public class RXCDiffArray<Element>: Collection {

    public typealias Iterator = RXCDiffArray.RXCIterator<Element>

    public var startIndex: Int {return 0}

    public var endIndex: Int {return self.contentArray.count-1}

    public func index(after i: Int) -> Int {
        return i + 1
    }

    public let contentArray:NSMutableArray

    public var threadSafe:Bool = true

    ///是否是线性的一维结构, 用于某些时候我们希望将整个数组作为一维结构来处理(即使数组是二维类型)
    public let linear:Bool

    public init(capacity:Int=0, linear:Bool) {
        self.linear = linear
        self.contentArray = NSMutableArray.init(capacity: capacity)
    }

    public convenience init(objects:Element...) {
        self.init(capacity: objects.count, linear: false)
        self.add(contentsOf: objects)
    }

    public convenience init(objects:[Element]) {
        self.init(capacity: objects.count, linear: false)
        self.add(contentsOf: objects)
    }

    //MARK: - Lock

    private func lockContent() {
        objc_sync_enter(self.contentArray)
    }

    private func unlockContent() {
        objc_sync_exit(self.contentArray)
    }

    //MARK: - R

    public var count:Int {return self.contentArray.count}

    public var isEmpty:Bool {return self.count == 0}

    public func safeGet(at index:Int)->Element?{
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        if index < 0 || index >= self.count {
            return nil
        }

        return self[index]
    }

    public var first:Element? {
        return self.safeGet(at: 0)
    }

    public var last:Element? {
        return self.safeGet(at: self.count-1)
    }

    public func first(where predicate: (Element) throws -> Bool) rethrows -> Element? {
        do {
            let safe:Bool = self.threadSafe
            if safe {self.lockContent()}
            defer {if safe {self.unlockContent()}}

            for i in self {
                if try predicate(i) {
                    return i
                }
            }
            return nil
        }catch {
            throw error
        }
    }

    public func last(where predicate: (Element) throws -> Bool) rethrows -> Element? {
        do {
            let safe:Bool = self.threadSafe
            if safe {self.lockContent()}
            defer {if safe {self.unlockContent()}}
            for i in (0..<self.count).reversed() {
                let object = self[i]
                if try predicate(object) {
                    return object
                }
            }
            return nil
        }catch {
            throw error
        }
    }

    public func firstIndex(where predicate: (Element) throws -> Bool) rethrows -> Int? {
        do {
            let safe:Bool = self.threadSafe
            if safe {self.lockContent()}
            defer {if safe {self.unlockContent()}}
            for (index, element) in self.enumerated() {
                if try predicate(element) {
                    return index
                }
            }
            return nil
        }catch {
            throw error
        }
    }

    public func lastIndex(where predicate: (Element) throws -> Bool) rethrows -> Int? {
        do {
            let safe:Bool = self.threadSafe
            if safe {self.lockContent()}
            defer {if safe {self.unlockContent()}}

            let reversedIndex = (0..<self.count).reversed()
            for i in reversedIndex {
                let object = self[i]
                if try predicate(object) {
                    return i
                }
            }
            return nil
        }catch {
            throw error
        }
    }

    //MARK: - C

    @discardableResult
    public func add(_ anObject: Element)->RDAChangeSet<Element> {
        return self.add(contentsOf: [anObject])
    }

    @discardableResult
    public func add(contentsOf objects: [Element])->RDAChangeSet<Element> {
        return self.insert(contentOf: objects, at: self.count)
    }

    @discardableResult
    public func insert(_ anObject:Element, at index:Int)->RDAChangeSet<Element> {
        return self.insert(contentOf: [anObject], at: index)
    }

    @discardableResult
    public func insert(contentOf objects:[Element], at index:Int)->RDAChangeSet<Element> {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        let range:Range<Int> = index..<index+objects.count
        let indexSet:IndexSet = IndexSet(integersIn: range)
        self.contentArray.insert(objects, at: indexSet)

        let changes:[RDAChangeSet<Element>.Change] = range.map({
            let insert = RDAChangeSet<Element>.ElementInsert(item: objects[$0-range.startIndex], section: 0, index: $0)
            return RDAChangeSet<Element>.Change.elementInsert(insert)
        })
        return RDAChangeSet(changes: changes)
    }

    /*

    //MARK: - U

    @discardableResult
    public func replace(at index: Int, with anObject: Element)->RDAChangeSet<Element> {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        let old = self[index]
        self.contentArray.replaceObject(at: index, with: anObject)

        let changes = [RDAChange.replace(RDAReplace(oldItem: old, newItem: anObject, index: index))]
        return changes
    }

    ///re-set the object so we have a chance to send change, drive the UI to refresh
    @discardableResult
    public func reload(at index:Int)->RDAChangeSet<Element> {
        let element = self[index]
        return self.replace(at: index, with: element)
    }

    @discardableResult
    public func move(from:Int, to:Int)->[RDAChange<Element>] {

        guard from != to else {return []}

        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        let fromValue = self[from]
        self.remove(at: from)
        self.insert(fromValue, at: to)

        return [RDAChange.move(RDAMove(item: fromValue, fromIndex: from, toIndex: to))]
    }

    @discardableResult
    public func exchange(index1:Int, index2:Int)->[RDAChange<Element>] {

        guard index1 != index2 else {return []}

        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        let value1 = self[index1]
        let value2 = self[index2]

        self.replace(at: index1, with: value2)
        self.replace(at: index2, with: value1)

        let move1 = RDAChange.move(RDAMove(item: value1, fromIndex: index1, toIndex: index2))
        let move2 = RDAChange.move(RDAMove(item: value2, fromIndex: index2, toIndex: index1))
        return [move1, move2]
    }

    //MARK: - D

    @discardableResult
    public func remove(at index: Int)->[RDAChange<Element>] {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        let removed = self[index]
        self.contentArray.removeObject(at: index)

        let changes = [RDAChange.delete(RDADelete(item: removed, index: index))]
        return changes
    }

    @discardableResult
    public func removeAll(where predicate: (Element) -> Bool)->[RDAChange<Element>] {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        var changes:[RDAChange<Element>] = []

        for i in self.enumerated() {
            if predicate(i.element) {
                changes.append(RDAChange.delete(RDADelete(item: i.element, index: i.offset)))
            }
        }
        //删除本地数据
        for i in changes.reversed() {
            self.remove(at: i.delete!.index)
        }

        return changes
    }

    @discardableResult
    public func removeAll()->[RDAChange<Element>] {
//        self.removeAll(where: {_ in return true})
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        let changes = self.enumerated().map({RDAChange.delete(RDADelete(item: $0.element, index: $0.offset))})
        self.contentArray.removeAllObjects()

        return changes
    }

    @discardableResult
    public func dropFirst()->[RDAChange<Element>]{
        if self.isEmpty {return []}
        return self.remove(at: 0)
    }

    @discardableResult
    public func dropLast()->[RDAChange<Element>] {
        if self.isEmpty {return []}
        return self.remove(at: self.count-1)
    }
    */

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

}

public extension RXCDiffArray {

    struct RXCIterator<Element>: IteratorProtocol {

        private let array:RXCDiffArray<Element,Element>
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

extension RXCDiffArray where Element: Equatable {

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

    public func batch(batchClosure:()->(), completion:([DeepDiff.RDAChange<Element>])->()) {
        let old:[Element] = [Element].init(self)
        batchClosure()
        let new:[Element] = [Element].init(self)
        let changes = DeepDiff.diff(old: old, new: new)
        completion(changes)
    }

}
#endif

extension RXCDiffArray where Element: RDASectionProtocol {

    func add() {
        let a = self.safeGet(at: 0)?.rda_sectionIdentifier
    }

}
