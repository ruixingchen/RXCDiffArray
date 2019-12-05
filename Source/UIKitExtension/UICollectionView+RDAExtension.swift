//
//  UICollectionView+RDAExtension.swift
//  RXCDiffArrayExample
//
//  Created by ruixingchen on 9/15/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import UIKit

extension UICollectionView {

    ///根据一个二维的改变来更新数据
    public func reload<Element>(with differences:[RDADifference<Element>], reloadDataSource:@escaping([Element])->Void, completion:((Bool)->Void)?) {

        guard self.window != .none else {
            if let data = differences.last?.dataAfterChange {
                reloadDataSource(data)
            }
            self.reloadData()
            completion?(true)
            return
        }

        let group = DispatchGroup()
        //由于DifferenceKit是分阶段进行的, 这里也必须要分阶段进行
        for difference in differences {
            let updateClosure:()->Void = {
                if let data = difference.dataAfterChange {
                    reloadDataSource(data)
                }
                for change in difference.changes {
                    switch change {
                    case .sectionRemove(offset: let offset):
                        self.deleteSections(IndexSet(integer: offset))
                    case .sectionInsert(offset: let offset):
                        self.insertSections(IndexSet(integer: offset))
                    case .sectionUpdate(offset: let offset):
                        self.reloadSections(IndexSet(integer: offset))
                    case .sectionMove(fromOffset: let from, toOffset: let to):
                        self.moveSection(from, toSection: to)
                    case .elementRemove(offset: let row, section: let section):
                        self.deleteItems(at: [IndexPath(row: row, section: section)])
                    case .elementInsert(offset: let row, section: let section):
                        self.insertItems(at: [IndexPath(row: row, section: section)])
                    case .elementUpdate(offset: let row, section: let section):
                        self.reloadItems(at: [IndexPath(row: row, section: section)])
                    case .elementMove(fromOffset: let fromRow, fromSection: let fromSection, toOffset: let toRow, toSection: let toSection):
                        self.moveItem(at: IndexPath(row: fromRow, section: fromSection), to: IndexPath(row: toRow, section: toSection))
                    }
                }
            }
            group.enter()
            self.performBatchUpdates(updateClosure) { (_) in
                group.leave()
            }
        }
        group.notify(queue: DispatchQueue.main) {
            completion?(true)
        }
    }

}
