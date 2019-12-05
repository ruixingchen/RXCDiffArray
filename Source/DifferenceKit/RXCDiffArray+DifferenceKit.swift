//
//  RXCDiffArray+DifferenceKit.swift
//  PINCache
//
//  Created by ruixingchen on 9/16/19.
//

import Foundation
#if canImport(DifferenceKit)
import DifferenceKit

///描述一个可以进行Diff的Row
public protocol RDADiffableRowElementProtocol {

    ///表示当前对象唯一性的对象, 一般来说返回一个唯一字符串即可, 如果两个identifier相等则在对比的时候认为是相同的元素
    var rda_diffIdentifier:AnyHashable {get}

}

///描述一个可以进行Diff的Section
public protocol RDADiffableSectionElementProtocol: RDASectionElementProtocol {
    ///表示当前对象唯一性的对象, 一般来说返回一个唯一字符串即可, 如果两个identifier相等则在对比的时候认为是相同的元素
    var rda_diffIdentifier:AnyHashable {get}
    ///表示某个Section含有的可以进行计较的Row, 虽然只需要对rda_elements做一个cast即可, 但是我们仍然定义一个属性来强制要求这个属性
    var rda_diffableElements:[RDADiffableRowElementProtocol] {get}

}

///Row的diff代理, 主要作用是将RowElement包装后传入DifferenceKit进行diff
public class RDARowDiffProxy: Differentiable {

    public typealias DifferenceIdentifier = AnyHashable

    public let element:RDADiffableRowElementProtocol

    public init(element:RDADiffableRowElementProtocol) {
        self.element = element
    }

    public var differenceIdentifier: AnyHashable {return self.element.rda_diffIdentifier}

    public func isContentEqual(to source: RDARowDiffProxy) -> Bool {
        return self.element.rda_diffIdentifier == source.element.rda_diffIdentifier
    }

}

///Section的Diff代理, 主要作用是将SectionElement包装后传入DifferenceKit
public class RDASectionDiffProxy: DifferentiableSection {

    public typealias DifferenceIdentifier = AnyHashable
    public typealias Collection = Array<RDARowDiffProxy>

    public var sectionElement:RDADiffableSectionElementProtocol
    ///element是主要的存储row的地方, 用于对比的row不可以和数据源产生关联, 否则可能会由于引用类型共用指针而导致对比结果为空
    public var elements: Array<RDARowDiffProxy>

    public init(sectionElement:RDADiffableSectionElementProtocol) {
        self.sectionElement = sectionElement
        self.elements = sectionElement.rda_diffableElements.map({RDARowDiffProxy(element: $0)})
    }

    public required init<C: Swift.Collection>(source: RDASectionDiffProxy, elements: C) where C.Element == RDARowDiffProxy {
        self.sectionElement = source.sectionElement
        self.elements = elements.map({$0})
    }

    public var differenceIdentifier: AnyHashable {return self.sectionElement.rda_diffIdentifier}

    public func isContentEqual(to source: RDASectionDiffProxy) -> Bool {
        return self.differenceIdentifier == source.differenceIdentifier
    }

}

extension RXCDiffArray {

    ///强制进行一维对比
    ///某些时候我们无法满足ElementContainer.Element: RDADiffableRowElementProtocol的条件, 如Element是一个协议, 可以调用这个接口进行强制转换后再对比, 调用的时候一定要小心, 类型不正确则会导致崩溃
    public func force_batchWithDifferenceKit_1D(section:Int=0, batch:()->Void)->[Difference] {
        let originProxies = self.map({RDARowDiffProxy(element: $0 as! RDADiffableRowElementProtocol)})
        batch()
        let currentProxies = self.map({RDARowDiffProxy(element: $0 as! RDADiffableRowElementProtocol)})
        let changeset = StagedChangeset(source: originProxies, target: currentProxies, section: section)
        let differences:[RDADifference<ElementContainer.Element>] = changeset.rda_toRDADifference()
        return differences
    }

    ///强制进行二维对比
    ///某些时候我们无法满足ElementContainer.Element: RDADiffableRowElementProtocol的条件, 如Element是一个协议, 可以调用这个接口进行强制转换后再对比, 调用的时候一定要小心, 类型不正确则会导致崩溃
    public func force_batchWithDifferenceKit_2D(batch:()->Void)->[Difference] {

        let originProxies = self.map { (section) -> RDASectionDiffProxy in
            return RDASectionDiffProxy(sectionElement: section as! RDADiffableSectionElementProtocol)
        }

        batch()

        let currentProxies = self.map { (section) -> RDASectionDiffProxy in
            return RDASectionDiffProxy(sectionElement: section as! RDADiffableSectionElementProtocol)
        }
        let changeset = StagedChangeset(source: originProxies, target: currentProxies)
        let differences:[RDADifference<ElementContainer.Element>] = changeset.rda_toRDADifference()
        return differences
    }

}

///一维 batch
extension RXCDiffArray where ElementContainer.Element: RDADiffableRowElementProtocol {

    ///进行一维batch, 只会进行一维方向上的对比
    public func batchWithDifferenceKit_1D(section:Int=0, batch:()->Void)->[Difference] {
        let originProxies = self.map({RDARowDiffProxy(element: $0)})
        batch()
        let currentProxies = self.map({RDARowDiffProxy(element: $0)})
        let changeset = StagedChangeset(source: originProxies, target: currentProxies, section: section)
        let differences:[RDADifference<ElementContainer.Element>] = changeset.rda_toRDADifference()
        return differences
    }
}

extension RXCDiffArray where ElementContainer.Element: RDADiffableSectionElementProtocol {

    ///二维batch, 进行二维方向上的对比
    public func batchWithDifferenceKit_2D(batch:()->Void)->[Difference] {

        let originProxies = self.map { (section) -> RDASectionDiffProxy in
            return RDASectionDiffProxy(sectionElement: section)
        }

        batch()

        let currentProxies = self.map { (section) -> RDASectionDiffProxy in
            return RDASectionDiffProxy(sectionElement: section)
        }
        let changeset = StagedChangeset(source: originProxies, target: currentProxies)
        let differences:[RDADifference<ElementContainer.Element>] = changeset.rda_toRDADifference()
        return differences
    }

}
#endif
