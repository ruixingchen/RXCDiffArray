//
//  UICollectionView+RDAExtension.swift
//  RXCDiffArrayExample
//
//  Created by ruixingchen on 9/15/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import UIKit

extension UICollectionView {

    public func reload<ElementContainer:Collection>(with difference:RDADifference<ElementContainer>, animations:RDATableViewAnimations, reloadDataSource:(ElementContainer)->Void, completion:((Bool)->Void)?) {

        guard self.window != .none else {
            if let data = difference.dataAfterChange {
                reloadDataSource(data)
            }
            self.reloadData()
            completion?(true)
            return
        }

        let updatesClosure:()->Void = {
            for i in difference.changes {
                switch i {
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

        if let data = difference.dataAfterChange {
            reloadDataSource(data)
        }

        self.performBatchUpdates(updatesClosure, completion: completion)
    }

    ///根据一个一维的改变来更新数据, 将改变映射到row的变化上
    public func reload<ElementContainer:Collection>(withDifference_1D_toRow difference:RDADifference<ElementContainer>, section:Int, reloadDataSource:(ElementContainer)->Void, completion:((Bool)->Void)?) {

        guard self.window != .none else {
            if let data = difference.dataAfterChange {
                reloadDataSource(data)
            }
            self.reloadData()
            completion?(true)
            return
        }

        let updatesClosure:()->Void = {
            for i in difference.changes {
                switch i {
                case .elementRemove(offset: let row, section: _):
                    self.deleteItems(at: [IndexPath(row: row, section: section)])
                case .elementInsert(offset: let row, section: _):
                    self.insertItems(at: [IndexPath(row: row, section: section)])
                case .elementUpdate(offset: let row, section: _):
                    self.reloadItems(at: [IndexPath(row: row, section: section)])
                case .elementMove(fromOffset: let fromRow, fromSection: _, toOffset: let toRow, toSection: _):
                    self.moveItem(at: IndexPath(row: fromRow, section: section), to: IndexPath(row: toRow, section: section))
                default:
                    break
                }
            }
        }

        if let data = difference.dataAfterChange {
            reloadDataSource(data)
        }

        self.performBatchUpdates(updatesClosure, completion: completion)
    }

    ///根据一个一维的改变来更新数据, 将改变映射到section的变化上
    public func reload<ElementContainer:Collection>(withDifference_1D_toSection difference:RDADifference<ElementContainer>, animations:RDATableViewAnimations, reloadDataSource:(ElementContainer)->Void, completion:((Bool)->Void)?) {

        guard self.window != .none else {
            if let data = difference.dataAfterChange {
                reloadDataSource(data)
            }
            self.reloadData()
            completion?(true)
            return
        }

        let updatesClosure:()->Void = {
            for i in difference.changes {
                switch i {
                case .elementRemove(offset: let row, section: _):
                    self.deleteSections(IndexSet.init(integer: row))
                case .elementInsert(offset: let row, section: _):
                    self.insertSections(IndexSet.init(integer: row))
                case .elementUpdate(offset: let row, section: _):
                    self.reloadSections(IndexSet.init(integer: row))
                case .elementMove(fromOffset: let fromRow, fromSection: _, toOffset: let toRow, toSection: _):
                    self.moveSection(fromRow, toSection: toRow)
                default:
                    break
                }
            }
        }

        if let data = difference.dataAfterChange {
            reloadDataSource(data)
        }
        self.performBatchUpdates(updatesClosure, completion: completion)
    }

}
