//
//  RDADifference+DifferenceKit.swift
//  RXCDiffArray
//
//  Created by ruixingchen on 11/4/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
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

    var rda_diffIdentifier:AnyHashable {get}
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

extension RDADifference where ElementContainer.Element: RDADiffableRowElementProtocol {

    /// 进行一维batch, 只会进行一维方向上的对比
    /// - Parameters:
    ///   - section: 返回的结果的section, 只影响最终返回结果, 不影响对比流程
    ///   - origin: 原始数据
    ///   - current: 改变后的数据
    public static func differences_1D(section:Int=0, between origin:ElementContainer, and current:ElementContainer)->[RDADifference<ElementContainer>] {
        //记录原始数据
        let originData = origin.map({RDARowDiffProxy.init(element: $0)})
        let currentData = current.map({RDARowDiffProxy.init(element: $0)})
        let changeSet = StagedChangeset(source: originData, target: currentData,section: section)
        let differences:[RDADifference<ElementContainer>] = changeSet.rda_toRDADifference()
        return differences
    }

}

extension RDADifference where ElementContainer.Element: RDADiffableSectionElementProtocol {

    ///returns the differences between two container in 2D
    public static func differences_2D(between origin:ElementContainer, and current:ElementContainer)->[RDADifference<ElementContainer>] {
        let originData = origin.map { (section) -> RDASectionDiffProxy in
            return RDASectionDiffProxy(sectionElement: section)
        }

        let currentData = current.map { (section) -> RDASectionDiffProxy in
            return RDASectionDiffProxy(sectionElement: section)
        }
        let changeset = StagedChangeset(source: originData, target: currentData)
        let differences:[RDADifference<ElementContainer>] = changeset.rda_toRDADifference()
        return differences
    }

}

extension StagedChangeset {

    public func rda_toRDADifference<ElementContainer: Swift.RangeReplaceableCollection>()->[RDADifference<ElementContainer>] {
        var differences:[RDADifference<ElementContainer>] = []
        for i in self {

            var changes:[RDADifference<ElementContainer>.Change] = []

            if !i.sectionDeleted.isEmpty {
                let _changes = i.sectionDeleted.map { (section) -> RDADifference<ElementContainer>.Change in
                    return RDADifference.Change.sectionRemove(offset: section)
                }
                changes.append(contentsOf: _changes)
            }
            if !i.sectionInserted.isEmpty {
                let _changes = i.sectionInserted.map { (section) -> RDADifference<ElementContainer>.Change in
                    return RDADifference.Change.sectionInsert(offset: section)
                }
                changes.append(contentsOf: _changes)
            }
            if !i.sectionUpdated.isEmpty {
                let _changes = i.sectionUpdated.map { (section) -> RDADifference<ElementContainer>.Change in
                    return RDADifference.Change.sectionUpdate(offset: section)
                }
                changes.append(contentsOf: _changes)
            }
            if !i.sectionMoved.isEmpty {
                let _changes = i.sectionMoved.map { (section) -> RDADifference<ElementContainer>.Change in
                    return RDADifference.Change.sectionMove(fromOffset: section.source, toOffset: section.target)
                }
                changes.append(contentsOf: _changes)
            }

            if !i.elementDeleted.isEmpty {
                let _changes = i.elementDeleted.map { (path) -> RDADifference<ElementContainer>.Change in
                    return RDADifference.Change.elementRemove(offset: path.element, section: path.section)
                }
                changes.append(contentsOf: _changes)
            }
            if !i.elementInserted.isEmpty {
                let _changes = i.elementInserted.map { (path) -> RDADifference<ElementContainer>.Change in
                    return RDADifference.Change.elementInsert(offset: path.element, section: path.section)
                }
                changes.append(contentsOf: _changes)
            }
            if !i.elementUpdated.isEmpty {
                let _changes = i.elementUpdated.map { (path) -> RDADifference<ElementContainer>.Change in
                    return RDADifference.Change.elementUpdate(offset: path.element, section: path.section)
                }
                changes.append(contentsOf: _changes)
            }
            if !i.elementMoved.isEmpty {
                let _changes = i.elementMoved.map { (path) -> RDADifference<ElementContainer>.Change in
                    return RDADifference.Change.elementMove(fromOffset: path.source.element, fromSection: path.source.section, toOffset: path.target.element, toSection: path.target.section)
                }
                changes.append(contentsOf: _changes)
            }
            var diff:RDADifference<ElementContainer> = RDADifference.init(changes: changes)
            let data = i.data.map { (mapElement) -> ElementContainer.Element in
                if let sectionProxy = mapElement as? RDASectionDiffProxy {
                    var section:RDASectionElementProtocol = sectionProxy.sectionElement
                    let elements:[RDADiffableRowElementProtocol] = sectionProxy.elements.map({$0.element})
                    section.rda_elements = elements
                    return section as! ElementContainer.Element
                }else if let rowProxy = mapElement as? RDARowDiffProxy {
                    return rowProxy.element as! ElementContainer.Element
                }else {
                    fatalError("WRONG TYPE")
                }
            }
            diff.dataAfterChange = ElementContainer.init(data)
            differences.append(diff)
        }
        return differences
    }

}
#endif
