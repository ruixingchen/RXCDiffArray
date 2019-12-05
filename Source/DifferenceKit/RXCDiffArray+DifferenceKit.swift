//
//  RXCDiffArray+DifferenceKit.swift
//  PINCache
//
//  Created by ruixingchen on 9/16/19.
//

import Foundation
#if canImport(DifferenceKit)
import DifferenceKit

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
