//
//  RXCDiffArray+DifferenceKit.swift
//  PINCache
//
//  Created by ruixingchen on 9/16/19.
//

import Foundation
#if canImport(DifferenceKit)
import DifferenceKit

///一维 batch
extension RXCDiffArray where ElementContainer.Element: RDADiffableRowElementProtocol {

    ///进行一维batch, 只会进行一维方向上的对比
    public func batchWithDifferenceKit_1D(section:Int=0, batch:()->Void)->[Difference] {
        let origin = ElementContainer.init(self.container)
        batch()
        let current = ElementContainer.init(self.container)
        return Difference.differences_1D(section: section, between: origin, and: current)
    }
}

extension RXCDiffArray where ElementContainer.Element: RDADiffableSectionElementProtocol {

    ///二维batch, 进行二维方向上的对比
    public func batchWithDifferenceKit_2D(batch:()->Void)->[Difference] {

        let origin = self.container
        batch()
        let current = self.container
        return Difference.differences_2D(between: origin, and: current)

//        let originData = self.map { (section) -> ArraySection<RDADiffableSectionElementWrapper, RDADiffableRowElementWrapper> in
//            let sectionWrapper = RDADiffableSectionElementWrapper(element: section)
//            let rowWrappers = section.rda_diffableElements.map({RDADiffableRowElementWrapper(element: $0)})
//            return ArraySection.init(model: sectionWrapper, elements: rowWrappers)
//        }
//        batch()
//        let currentData = self.map { (section) -> ArraySection<RDADiffableSectionElementWrapper, RDADiffableRowElementWrapper> in
//            let sectionWrapper = RDADiffableSectionElementWrapper(element: section)
//            let rowWrappers = section.rda_diffableElements.map({RDADiffableRowElementWrapper(element: $0)})
//            return ArraySection.init(model: sectionWrapper, elements: rowWrappers)
//        }
//        let changeset = StagedChangeset(source: originData, target: currentData)
//        let differences:[Difference] = changeset.rda_toDifference()
//        return differences
    }

}
#endif
