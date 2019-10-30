//
//  UITableView+RDAExtension.swift
//  RXCDiffArrayExample
//
//  Created by ruixingchen on 9/14/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import UIKit

extension UITableView {

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
                    self.deleteSections(IndexSet(integer: offset), with: animations.deleteSection)
                case .sectionInsert(offset: let offset):
                    self.insertSections(IndexSet(integer: offset), with: animations.insertSection)
                case .sectionUpdate(offset: let offset):
                    self.reloadSections(IndexSet(integer: offset), with: animations.reloadSection)
                case .sectionMove(fromOffset: let from, toOffset: let to):
                    self.moveSection(from, toSection: to)
                case .elementRemove(offset: let row, section: let section):
                    self.deleteRows(at: [IndexPath(row: row, section: section)], with: animations.deleteRow)
                case .elementInsert(offset: let row, section: let section):
                    self.insertRows(at: [IndexPath(row: row, section: section)], with: animations.insertRow)
                case .elementUpdate(offset: let row, section: let section):
                    self.reloadRows(at: [IndexPath(row: row, section: section)], with: animations.reloadRow)
                case .elementMove(fromOffset: let fromRow, fromSection: let fromSection, toOffset: let toRow, toSection: let toSection):
                    self.moveRow(at: IndexPath(row: fromRow, section: fromSection), to: IndexPath(row: toRow, section: toSection))
                }
            }
        }

        if let data = difference.dataAfterChange {
            reloadDataSource(data)
        }

        if #available(iOS 11, *) {
            self.performBatchUpdates(updatesClosure, completion: completion)
        }else {
            self.beginUpdates()
            updatesClosure()
            self.endUpdates()
            completion?(true)
        }
    }

}
