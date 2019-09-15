//
//  RDATableViewReloadAnimations.swift
//  RXCDiffArrayExample
//
//  Created by ruixingchen on 9/15/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import UIKit

public struct RDAReloadAnimations {
    var deleteSection:UITableView.RowAnimation = .automatic
    var insertSection:UITableView.RowAnimation = .automatic
    var reloadSection:UITableView.RowAnimation = .automatic
    var deleteRow:UITableView.RowAnimation = .automatic
    var insertRow:UITableView.RowAnimation = .automatic
    var reloadRow:UITableView.RowAnimation = .automatic

    init(deleteSection:UITableView.RowAnimation, insertSection:UITableView.RowAnimation, reloadSection:UITableView.RowAnimation, deleteRow:UITableView.RowAnimation, insertRow:UITableView.RowAnimation, reloadRow:UITableView.RowAnimation) {
        self.deleteSection = deleteSection
        self.insertSection = insertSection
        self.reloadSection = reloadSection
        self.deleteRow = deleteRow
        self.insertRow = insertRow
        self.reloadRow = reloadRow
    }

    static func none()->RDAReloadAnimations {
        return RDAReloadAnimations(deleteSection: .none, insertSection: .none, reloadSection: .none, deleteRow: .none, insertRow: .none, reloadRow: .none)
    }

    static func automatic()->RDAReloadAnimations {
        return RDAReloadAnimations(deleteSection: .automatic, insertSection: .automatic, reloadSection: .automatic, deleteRow: .automatic, insertRow: .automatic, reloadRow: .automatic)
    }
}
