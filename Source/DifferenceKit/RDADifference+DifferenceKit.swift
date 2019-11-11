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

///将我们自己的RDADiffableRowElementProtocol包装成DK的Differentiable
public class RDADiffableRowElementWrapper: Differentiable, RDADiffableRowElementProtocol {

    public typealias DifferenceIdentifier = AnyHashable

    let element:RDADiffableRowElementProtocol

    init(element:RDADiffableRowElementProtocol) {
        self.element = element
    }

    public var differenceIdentifier: AnyHashable {return self.element.rda_diffIdentifier}
    public var rda_diffIdentifier: AnyHashable  {return self.element.rda_diffIdentifier}

    public func isContentEqual(to source: RDADiffableRowElementWrapper) -> Bool {
        return self.element.rda_diffIdentifier == source.element.rda_diffIdentifier
    }

}

///将我们自己的RDADiffableSectionElementProtocol包装成DK的Differentiable
internal class RDADiffableSectionElementWrapper: Differentiable, RDADiffableSectionElementProtocol {

    internal typealias DifferenceIdentifier = AnyHashable

    internal var element:RDADiffableSectionElementProtocol

    internal init(element:RDADiffableSectionElementProtocol) {
        self.element = element
    }

    internal var differenceIdentifier: AnyHashable {return self.element.rda_diffIdentifier}

    internal var rda_diffIdentifier: AnyHashable {return self.element.rda_diffIdentifier}

    internal var rda_diffableElements: [RDADiffableRowElementProtocol] {return self.element.rda_diffableElements}

    internal var rda_elements: [Any] {
        get {return self.element.rda_elements}
        set {self.element.rda_elements = newValue}
    }

    internal func isContentEqual(to source: RDADiffableSectionElementWrapper) -> Bool {
        return self.element.rda_diffIdentifier == source.element.rda_diffIdentifier
    }

}

extension StagedChangeset {

    internal func rda_toDifference<ElementContainer: Swift.RangeReplaceableCollection>()->[RDADifference<ElementContainer>] {
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
                if let arraySection = mapElement as? ArraySection<RDADiffableSectionElementWrapper, RDADiffableRowElementWrapper> {
                    var section:RDASectionElementProtocol = arraySection.model.element
                    let rowElementWrappers:[RDADiffableRowElementWrapper] = arraySection.elements
                    let elements:[RDADiffableRowElementProtocol] = rowElementWrappers.map({
                        $0.element
                    })
                    section.rda_elements = elements
                    return section as! ElementContainer.Element
                }else if let wrapper = mapElement as? RDADiffableRowElementWrapper {
                    return wrapper.element as! ElementContainer.Element
                }else {
                    fatalError()
                }
            }
            diff.dataAfterChange = ElementContainer.init(data)
            differences.append(diff)
        }
        return differences
    }

}

extension RDADifference where ElementContainer.Element: RDADiffableSectionElementProtocol {

    ///returns the differences between two container in 2D
    public static func differences_2D(between origin:ElementContainer, and current:ElementContainer)->[RDADifference<ElementContainer>] {
        let originData = origin.map { (section) -> ArraySection<RDADiffableSectionElementWrapper, RDADiffableRowElementWrapper> in
            let sectionWrapper = RDADiffableSectionElementWrapper(element: section)
            let rowWrappers = section.rda_diffableElements.map({RDADiffableRowElementWrapper(element: $0)})
            return ArraySection.init(model: sectionWrapper, elements: rowWrappers)
        }

        let currentData = current.map { (section) -> ArraySection<RDADiffableSectionElementWrapper, RDADiffableRowElementWrapper> in
            let sectionWrapper = RDADiffableSectionElementWrapper(element: section)
            let rowWrappers = section.rda_diffableElements.map({RDADiffableRowElementWrapper(element: $0)})
            return ArraySection.init(model: sectionWrapper, elements: rowWrappers)
        }
        let changeset = StagedChangeset(source: originData, target: currentData)
        let differences:[RDADifference<ElementContainer>] = changeset.rda_toDifference()
        return differences
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
        let originData = origin.map({RDADiffableRowElementWrapper.init(element: $0)})
        let currentData = current.map({RDADiffableRowElementWrapper.init(element: $0)})
        let changeSet = StagedChangeset(source: originData, target: currentData,section: section)
        let differences:[RDADifference<ElementContainer>] = changeSet.rda_toDifference()
        return differences
    }

}

#endif
