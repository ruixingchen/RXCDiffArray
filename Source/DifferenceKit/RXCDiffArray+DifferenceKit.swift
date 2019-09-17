//
//  RXCDiffArray+DifferenceKit.swift
//  PINCache
//
//  Created by ruixingchen on 9/16/19.
//

import Foundation

public extension RXCDiffArray {

    ///进行批量处理后使用 DifferenceKit 计算差异, 返回计算结果
    ///返回的结果是一个数组, 且后一个数组的数据是依赖于前一个数组的, 将前一个数组的改变映射到UI上后才可以进行下一个数组的映射
    ///注意在修改的同时需要传入userInfo, 让batch期间的操作只针对数据而不影响UI
    func batchWithDifferenceKit(batch:()->Void)->[Difference] {
        let safe:Bool = self.threadSafe
        if safe {self.lockContent()}
        defer {if safe {self.unlockContent()}}

        let oldElements = self.contentCollection.map { (i) -> SimpleArraySection<Differentiable, Differentiable> in
            let section:Differentiable = i as! Differentiable
            let elements:[Differentiable] = ((section as! SectionElementProtocol).rda_elements as! [Differentiable])
            return SimpleArraySection(model: section, elements: elements)
        }
        batch()
        let newElements = self.contentCollection.map { (i) -> SimpleArraySection<Differentiable, Differentiable> in
            let section:Differentiable = i as! Differentiable
            let elements:[Differentiable] = ((section as! SectionElementProtocol).rda_elements as! [Differentiable])
            return SimpleArraySection(model: section, elements: elements)
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
            var diff = Difference(changes: changes)
            ///每一个步骤的数据
            let stepData = i.data
            diff.dk_finalDataForCurrentStep = ContiguousArray.init(stepData.map({ (i) -> SectionElement in
                var section = i.model as! SectionElementProtocol
                let element = i.elements as! [RowElement]
                section.rda_elements = element
                return section as! SectionContainer.Element
            }))
            differences.append(diff)
        }
        return differences
    }

}
