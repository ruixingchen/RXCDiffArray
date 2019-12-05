//
//  RDATableViewReloadAnimations.swift
//  RXCDiffArrayExample
//
//  Created by ruixingchen on 9/15/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import UIKit

public struct RDATableViewAnimations {

    public var deleteSection:UITableView.RowAnimation = .automatic
    public var insertSection:UITableView.RowAnimation = .automatic
    public var reloadSection:UITableView.RowAnimation = .automatic
    public var deleteRow:UITableView.RowAnimation = .automatic
    public var insertRow:UITableView.RowAnimation = .automatic
    public var reloadRow:UITableView.RowAnimation = .automatic

    public init(deleteSection:UITableView.RowAnimation, insertSection:UITableView.RowAnimation, reloadSection:UITableView.RowAnimation, deleteRow:UITableView.RowAnimation, insertRow:UITableView.RowAnimation, reloadRow:UITableView.RowAnimation) {
        self.deleteSection = deleteSection
        self.insertSection = insertSection
        self.reloadSection = reloadSection
        self.deleteRow = deleteRow
        self.insertRow = insertRow
        self.reloadRow = reloadRow
    }

    public static func none()->RDATableViewAnimations {
        return RDATableViewAnimations(deleteSection: .none, insertSection: .none, reloadSection: .none, deleteRow: .none, insertRow: .none, reloadRow: .none)
    }

    public static func automatic()->RDATableViewAnimations {
        return RDATableViewAnimations(deleteSection: .automatic, insertSection: .automatic, reloadSection: .automatic, deleteRow: .automatic, insertRow: .automatic, reloadRow: .automatic)
    }
}
