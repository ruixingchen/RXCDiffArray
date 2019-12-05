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

extension RDADifference {

    /// 进行一维batch, 只会进行一维方向上的对比
    /// - Parameters:
    ///   - section: 返回的结果的section, 只影响最终返回结果, 不影响对比流程
    ///   - origin: 原始数据
    ///   - current: 改变后的数据
    public static func differences_1D(section:Int=0, between origin:[RDADiffableRowElementProtocol], and current:[RDADiffableRowElementProtocol])->[RDADifference<RDADiffableRowElementProtocol>] {
        //记录原始数据
        let originData = origin.map({RDARowDiffProxy.init(element: $0)})
        let currentData = current.map({RDARowDiffProxy.init(element: $0)})
        let changeSet = StagedChangeset(source: originData, target: currentData,section: section)
        let differences:[RDADifference<RDADiffableRowElementProtocol>] = changeSet.rda_toRDADifference()
        return differences
    }

    public static func differences_2D(between origin:[RDADiffableSectionElementProtocol], and current:[RDADiffableSectionElementProtocol])->[RDADifference<RDADiffableSectionElementProtocol>] {
        let originData = origin.map { (section) -> RDASectionDiffProxy in
            return RDASectionDiffProxy(sectionElement: section)
        }

        let currentData = current.map { (section) -> RDASectionDiffProxy in
            return RDASectionDiffProxy(sectionElement: section)
        }
        let changeset = StagedChangeset(source: originData, target: currentData)
        let differences:[RDADifference<RDADiffableSectionElementProtocol>] = changeset.rda_toRDADifference()
        return differences
    }

}
#endif
