//
//  UICollectionView+RDAExtension.swift
//  RXCDiffArrayExample
//
//  Created by ruixingchen on 9/15/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import UIKit

extension UICollectionView {

    public func reload<SectionElement, SubElement>(with difference:RDADifference<SectionElement, SubElement>, completion:((Bool)->Void)?) where SectionElement: SectionElementProtocol, SubElement==SectionElement.SubElementContainer.Element {

        guard self.window != .none else {
            self.reloadData()
            return
        }

        let updatesClosure:()->Void = {

            if !difference.sectionRemoved.isEmpty {
                self.deleteSections(IndexSet(difference.sectionRemoved.map({$0.offset})))
            }
            if !difference.sectionInserted.isEmpty {
                self.insertSections(IndexSet(difference.sectionInserted.map({$0.offset})))
            }
            if !difference.sectionUpdated.isEmpty {
                self.reloadSections(IndexSet(difference.sectionUpdated.map({$0.offset})))
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
                self.deleteItems(at: indexPathes)
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
                self.insertItems(at: indexPathes)
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
                self.reloadItems(at: indexPathes)
            }
            for i in difference.elementMoved {
                switch i {
                case .elementMove(fromOffset: let fromRow, fromSection: let fromSection, toOffset: let toRow, toSection: let toSection, element: _):
                    self.moveItem(at: IndexPath(row: fromRow, section: fromSection), to: IndexPath(row: toRow, section: toSection))
                default:break
                }
            }
        }

        self.performBatchUpdates(updatesClosure, completion: completion)
    }

}
