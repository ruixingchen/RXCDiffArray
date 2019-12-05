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

///the delegate protocol
public protocol RXCDiffArrayDelegate: AnyObject {

    func diffArray<ElementContainer: RangeReplaceableCollection>(diffArray:RXCDiffArray<ElementContainer>, didModifiedWith differences:[RDADifference<ElementContainer.Element>])

}

public struct RXCDiffArrayKey {
    ///if we do not want to notify delegates, pass false in the userInfo
    public static var notify:String {return "RXCDiffArray_notify"}
    ///if we are already in the barrier flag, pass true to avoid dead lock, internal use
    //internal static var avoid_barrier:String {return "RXCDiffArray_avoid_barrier"}
}

internal func rdalog(_ closure:@autoclosure ()->Any, file:StaticString = #file,line:Int = #line,function:StaticString = #function) {
    if RXCDiffArrayDebugMode {
        let fileName = String(describing: file).components(separatedBy: "/").last ?? ""
        print("-----\(fileName):\(line) - \(function) :\n \(closure())")
    }
}

public var RXCDiffArrayDebugMode:Bool = false

///一个简单的可以通知代理自身改变的数组, 同时可以通过泛型来定义真实的数据存储对象
///a simple array that can notify changes to delegates, and can define the real storage container object width GenericType
public final class RXCDiffArray<ElementContainer: RangeReplaceableCollection>: Collection, CustomStringConvertible where ElementContainer.Index == Int {

    public typealias Element = ElementContainer.Element
    public typealias Index = ElementContainer.Index
    public typealias Difference = RDADifference<ElementContainer.Element>

    ///the queue to implement multi read single write
    internal lazy var readWriteQueue:DispatchQueue = DispatchQueue.init(label: "RXCDiffArrayReadWriteQueue", qos: .default, attributes: .concurrent)
    ///用于实现等待功能
    ///for implement wait
    internal lazy var readWriteQueueGroup:DispatchGroup = DispatchGroup()

    ///the real storage container
    internal var container:ElementContainer = ElementContainer.init()

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

    public var description: String {
        var str:String = "RXCDiffArray:["
        for i in self {
            str += String.init(describing: i)
            str += "\n"
        }
        str += "]"
        return str
    }

    //MARK: - Collection Property

    public var count: Int {
        return self.container.count
    }
    public var underestimatedCount: Int {
        return self.container.underestimatedCount
    }
    public var isEmpty: Bool {
        return self.container.isEmpty
    }
    public func index(after i: ElementContainer.Index) -> ElementContainer.Index {
        return self.container.index(after: i)
    }
    public var startIndex: ElementContainer.Index {
        return self.container.startIndex
    }
    public var endIndex: ElementContainer.Index {
        return self.container.endIndex
    }

    public subscript(position: ElementContainer.Index) -> ElementContainer.Element {
        return self.container[position]
    }

    //MARK: - Tool

    ///will execute in sync mode
    internal func safeReadExecute(closure:()->Void) {
        self.readWriteQueue.sync {
            closure()
        }
    }

    //if we want to wait, the do not do heavy tasks
    internal func safeWriteExecute(wait:Bool=true, userInfo:[AnyHashable:Any]?, closure:@escaping ()->Void) {
        self.readWriteQueue.async(group: self.readWriteQueueGroup, qos: .default, flags: .barrier, execute: closure)
        if wait {
            self.readWriteQueueGroup.wait()
        }
    }

}
