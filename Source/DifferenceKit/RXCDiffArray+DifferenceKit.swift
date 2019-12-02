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
        let originProxies = self.map({RDARowDiffProxy(element: $0)})
        batch()
        let currentProxies = self.map({RDARowDiffProxy(element: $0)})
        let changeset = StagedChangeset(source: originProxies, target: currentProxies, section: section)
        let differences:[RDADifference<ElementContainer>] = changeset.rda_toDifference()
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
        let differences:[RDADifference<ElementContainer>] = changeset.rda_toDifference()
        return differences
    }

}
#endif
