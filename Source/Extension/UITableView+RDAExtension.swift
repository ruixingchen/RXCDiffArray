//
//  UITableView+RDAExtension.swift
//  RXCDiffArrayExample
//
//  Created by ruixingchen on 9/14/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import UIKit

public extension UITableView {

    func reload<SectionElement, SubElement>(with difference:RDADifference<SectionElement, SubElement>, animations:RDATableViewAnimations, completion:((Bool)->Void)?) {

        guard self.window != .none else {
            self.reloadData()
            return
        }

        let updatesClosure:()->Void = {

            if !difference.sectionRemoved.isEmpty {
                self.deleteSections(IndexSet(difference.sectionRemoved.map({$0.offset})), with: animations.deleteSection)
            }
            if !difference.sectionInserted.isEmpty {
                self.insertSections(IndexSet(difference.sectionInserted.map({$0.offset})), with: animations.insertSection)
            }
            if !difference.sectionUpdated.isEmpty {
                self.reloadSections(IndexSet(difference.sectionUpdated.map({$0.offset})), with: animations.reloadSection)
            }
            for i in difference.sectionMoved {
                switch i {
                case .sectionMove(fromOffset: let from, toOffset: let to, element: _):
                    self.moveSection(from, toSection: to)
                default:
                    assertionFailure("sectionMoved 中含有非法的枚举类型")
                    break
                }
            }
            if !difference.elementRemoved.isEmpty {
                var indexPathes:[IndexPath] = []
                for i in difference.elementRemoved {
                    switch i {
                    case .elementRemove(offset: let row, section: let section, element: _):
                        indexPathes.append(IndexPath(row: row, section: section))
                    default:
                        break
                    }
                }
                self.deleteRows(at: indexPathes, with: animations.deleteRow)
            }
            if !difference.elementInserted.isEmpty {
                var indexPathes:[IndexPath] = []
                for i in difference.elementInserted {
                    switch i {
                    case .elementInsert(offset: let row, section: let section, element: _):
                        indexPathes.append(IndexPath(row: row, section: section))
                    default:
                        break
                    }
                }
                self.insertRows(at: indexPathes, with: animations.insertRow)
            }
            if !difference.elementUpdated.isEmpty {
                var indexPathes:[IndexPath] = []
                for i in difference.elementUpdated {
                    switch i {
                    case .elementUpdate(offset: let row, section: let section, oldElement: _, newElement: _):
                        indexPathes.append(IndexPath(row: row, section: section))
                    default:
                        break
                    }
                }
                self.reloadRows(at: indexPathes, with: animations.reloadRow)
            }
            for i in difference.elementMoved {
                switch i {
                case .elementMove(fromOffset: let fromRow, fromSection: let fromSection, toOffset: let toRow, toSection: let toSection, element: _):
                    self.moveRow(at: IndexPath(row: fromRow, section: fromSection), to: IndexPath(row: toRow, section: toSection))
                default:break
                }
            }
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
