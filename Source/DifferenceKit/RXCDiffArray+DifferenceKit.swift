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

    var rda_diffIdentifier:AnyHashable {get}

}

///描述一个可以进行Diff的Section
public protocol RDADiffableSectionElementProtocol: RDASectionElementProtocol {

    var rda_diffIdentifier:AnyHashable {get}
    var rda_diffableElements:[RDADiffableRowElementProtocol] {get}

}

///将我们自己的RDADiffableRowElementProtocol包装成DK的Differentiable
internal class RDADifferentiableRowElementWrapper: Differentiable {

    typealias DifferenceIdentifier = AnyHashable

    let element:RDADiffableRowElementProtocol

    init(element:RDADiffableRowElementProtocol) {
        self.element = element
    }

    var differenceIdentifier: AnyHashable {return self.element.rda_diffIdentifier}

    func isContentEqual(to source: RDADifferentiableRowElementWrapper) -> Bool {
        return self.element.rda_diffIdentifier == source.element.rda_diffIdentifier
    }

}

///将我们自己的RDADiffableSectionElementProtocol包装成DK的Differentiable
internal class RDADifferentiableSectionElementWrapper: Differentiable {

    typealias DifferenceIdentifier = AnyHashable

    let element:RDADiffableSectionElementProtocol

    init(element:RDADiffableSectionElementProtocol) {
        self.element = element
    }

    var differenceIdentifier: AnyHashable {return self.element.rda_diffIdentifier}

    func isContentEqual(to source: RDADifferentiableSectionElementWrapper) -> Bool {
        return self.element.rda_diffIdentifier == source.element.rda_diffIdentifier
    }

}

internal extension StagedChangeset {

    func rda_toDifference<ElementContainer: RangeReplaceableCollection>()->[RDADifference<ElementContainer>] {
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
                if let arraySection = mapElement as? ArraySection<RDADifferentiableSectionElementWrapper, RDADifferentiableRowElementWrapper> {
                    var section:RDASectionElementProtocol = arraySection.model.element
                    let rowElementWrappers:[RDADifferentiableRowElementWrapper] = arraySection.elements
                    let elements:[RDADiffableRowElementProtocol] = rowElementWrappers.map({
                        $0.element
                    })
                    section.rda_elements = elements
                    return section as! ElementContainer.Element
                }else if let wrapper = mapElement as? RDADifferentiableRowElementWrapper {
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

///一维 batch
extension RXCDiffArray where ElementContainer.Element: RDADiffableRowElementProtocol {

    public func batchWithDifferenceKit_1D(batch:()->Void)->[Difference] {
        //记录原始数据
        let originData = self.map({RDADifferentiableRowElementWrapper.init(element: $0)})
        batch()
        let currentData = self.map({RDADifferentiableRowElementWrapper.init(element: $0)})
        let changeSet = StagedChangeset(source: originData, target: currentData, section: 0)
        //将DK的changeSet转换为我们自己的Change
        let differences:[Difference] = changeSet.rda_toDifference()
        return differences
    }
}

extension RXCDiffArray where ElementContainer.Element: RDADiffableSectionElementProtocol {

    public func batchWithDifferenceKit_2D(batch:()->Void)->[Difference] {
        //记录原始数据
        let originData = self.map { (section) -> ArraySection<RDADifferentiableSectionElementWrapper, RDADifferentiableRowElementWrapper> in
            let sectionWrapper = RDADifferentiableSectionElementWrapper(element: section)
            let rowWrappers = section.rda_diffableElements.map({RDADifferentiableRowElementWrapper(element: $0)})
            return ArraySection.init(model: sectionWrapper, elements: rowWrappers)
        }
        batch()
        let currentData = self.map { (section) -> ArraySection<RDADifferentiableSectionElementWrapper, RDADifferentiableRowElementWrapper> in
            let sectionWrapper = RDADifferentiableSectionElementWrapper(element: section)
            let rowWrappers = section.rda_diffableElements.map({RDADifferentiableRowElementWrapper(element: $0)})
            return ArraySection.init(model: sectionWrapper, elements: rowWrappers)
        }
        let changeset = StagedChangeset(source: originData, target: currentData)
        let differences:[Difference] = changeset.rda_toDifference()
        return differences
    }

}
#endif
