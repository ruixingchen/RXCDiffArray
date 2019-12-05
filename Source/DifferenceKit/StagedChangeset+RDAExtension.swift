//
//  StagedChangeset+RDAExtension.swift
//  RXCDiffArray
//
//  Created by ruixingchen on 12/5/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import Foundation
#if canImport(DifferenceKit)
import DifferenceKit

extension StagedChangeset {

    ///将StagedChangeset转换为RDADifference, 如果data是一个DiffProxy, 会进行 unbox, 保证RDADifference的data是裸数据
    internal func rda_toRDADifference<Element>()->[RDADifference<Element>] {
        var differences:[RDADifference<Element>] = []
        for i in self {

            var changes:[RDADifference<Element>.Change] = []

            //下面的读取顺序最好不要改动

            if !i.sectionDeleted.isEmpty {
                let _changes = i.sectionDeleted.map { (section) -> RDADifference<Element>.Change in
                    return RDADifference.Change.sectionRemove(offset: section)
                }
                changes.append(contentsOf: _changes)
            }
            if !i.sectionInserted.isEmpty {
                let _changes = i.sectionInserted.map { (section) -> RDADifference<Element>.Change in
                    return RDADifference.Change.sectionInsert(offset: section)
                }
                changes.append(contentsOf: _changes)
            }
            if !i.sectionUpdated.isEmpty {
                let _changes = i.sectionUpdated.map { (section) -> RDADifference<Element>.Change in
                    return RDADifference.Change.sectionUpdate(offset: section)
                }
                changes.append(contentsOf: _changes)
            }
            if !i.sectionMoved.isEmpty {
                let _changes = i.sectionMoved.map { (section) -> RDADifference<Element>.Change in
                    return RDADifference.Change.sectionMove(fromOffset: section.source, toOffset: section.target)
                }
                changes.append(contentsOf: _changes)
            }

            if !i.elementDeleted.isEmpty {
                let _changes = i.elementDeleted.map { (path) -> RDADifference<Element>.Change in
                    return RDADifference.Change.elementRemove(offset: path.element, section: path.section)
                }
                changes.append(contentsOf: _changes)
            }
            if !i.elementInserted.isEmpty {
                let _changes = i.elementInserted.map { (path) -> RDADifference<Element>.Change in
                    return RDADifference.Change.elementInsert(offset: path.element, section: path.section)
                }
                changes.append(contentsOf: _changes)
            }
            if !i.elementUpdated.isEmpty {
                let _changes = i.elementUpdated.map { (path) -> RDADifference<Element>.Change in
                    return RDADifference.Change.elementUpdate(offset: path.element, section: path.section)
                }
                changes.append(contentsOf: _changes)
            }
            if !i.elementMoved.isEmpty {
                let _changes = i.elementMoved.map { (path) -> RDADifference<Element>.Change in
                    return RDADifference.Change.elementMove(fromOffset: path.source.element, fromSection: path.source.section, toOffset: path.target.element, toSection: path.target.section)
                }
                changes.append(contentsOf: _changes)
            }
            var diff:RDADifference<Element> = RDADifference.init(changes: changes)
            let data = i.data.map { (mapElement) -> Element in
                if let sectionProxy = mapElement as? RDASectionDiffProxy {
                    var section:RDASectionElementProtocol = sectionProxy.sectionElement
                    let elements:[RDADiffableRowElementProtocol] = sectionProxy.elements.map({$0.element})
                    section.rda_elements = elements
                    return section as! Element
                }else if let rowProxy = mapElement as? RDARowDiffProxy {
                    return rowProxy.element as! Element
                }else {
                    fatalError("WRONG TYPE")
                }
            }
            diff.dataAfterChange = data
            differences.append(diff)
        }
        return differences
    }

}

#endif
