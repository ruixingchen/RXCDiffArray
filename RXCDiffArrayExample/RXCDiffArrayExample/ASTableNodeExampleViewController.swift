//
//  ASTableNodeExampleViewController.swift
//  RXCDiffArrayExample
//
//  Created by ruixingchen on 9/15/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import UIKit
#if canImport(AsyncDisplayKit)
import AsyncDisplayKit

class TitleCell: ASCellNode {

    let titleLabel: ASTextNode = ASTextNode()

    override init() {
        super.init()
        self.automaticallyManagesSubnodes = true
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        self.titleLabel.style.spacingBefore = 16
        let stack = ASStackLayoutSpec(direction: .horizontal, spacing: 0, justifyContent: .start, alignItems: .center, children: [self.titleLabel])
        stack.style.height = ASDimension.init(unit: .points, value: 44)
        return stack
    }

}

class ASTableNodeExampleViewController: UIViewController, ASTableDataSource, ASTableDelegate, RXCDiffArrayDelegate {

    let dataList:RXCDiffArray<[Card]> = RXCDiffArray()

    let tableView:ASTableNode = ASTableNode(style: .grouped)
    let bottomToolBar = UIToolbar()
    let bottomToolBar1 = UIToolbar()

    @objc func injected() {
        print("injected")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.dataList.threadSafe = true
        self.dataList.rda_appendSection(contentsOf: Card.random(countRange: 3..<4, elementCountRange: 3..<4), userInfo: ["notify": false])
        self.dataList.delegate = self

        self.tableView.displaysAsynchronously = false
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 88, right: 0)
        self.view.addSubnode(self.tableView)
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.reloadData()

        var navItems:[UIBarButtonItem] = []
        navItems.append(UIBarButtonItem(title: "add", style: .plain, target: self, action: #selector(addSection)))
        navItems.append(UIBarButtonItem(title: "insert", style: .plain, target: self, action: #selector(insertSection)))
        navItems.append(UIBarButtonItem(title: "delete", style: .plain, target: self, action: #selector(deleteSection)))
        navItems.append(UIBarButtonItem(title: "replace", style: .plain, target: self, action: #selector(replaceSection)))
        navItems.append(UIBarButtonItem(title: "move", style: .plain, target: self, action: #selector(moveSection)))
        self.navigationItem.rightBarButtonItems = navItems.reversed()

        self.view.addSubview(self.bottomToolBar)
        var toolBarItems:[UIBarButtonItem] = []
        toolBarItems.append(UIBarButtonItem(title: "add", style: .plain, target: self, action: #selector(addRow)))
        toolBarItems.append(UIBarButtonItem(title: "insert", style: .plain, target: self, action: #selector(insertRow)))
        toolBarItems.append(UIBarButtonItem(title: "delete", style: .plain, target: self, action: #selector(deleteRow)))
        toolBarItems.append(UIBarButtonItem(title: "replace", style: .plain, target: self, action: #selector(replaceRow)))
        toolBarItems.append(UIBarButtonItem(title: "move", style: .plain, target: self, action: #selector(moveRow)))
        self.bottomToolBar.items = toolBarItems

        self.view.addSubview(self.bottomToolBar1)
        var toolBarItems1:[UIBarButtonItem] = []
        toolBarItems1.append(UIBarButtonItem(title: "reload", style: .plain, target: self, action: #selector(reload)))
        toolBarItems1.append(UIBarButtonItem(title: "print", style: .plain, target: self, action: #selector(printDataSource)))
        toolBarItems1.append(UIBarButtonItem(title: "test", style: .plain, target: self, action: #selector(test)))
        self.bottomToolBar1.items = toolBarItems1

    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.tableView.frame = self.view.frame
        if #available(iOS 11.0, *) {
            self.bottomToolBar1.frame = CGRect(x: 0, y: self.view.bounds.height-self.view.safeAreaInsets.bottom-44, width: self.view.bounds.width, height: 44)
        } else {
            self.bottomToolBar1.frame = CGRect(x: 0, y: self.view.bounds.height-self.bottomLayoutGuide.length-44, width: self.view.bounds.width, height: 44)
        }
        self.bottomToolBar.frame = CGRect(x: 0, y: self.bottomToolBar1.frame.origin.y-44, width: self.bottomToolBar1.frame.width, height: 44)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }

    func numberOfSections(in tableNode: ASTableNode) -> Int {
        return self.dataList.count
    }

    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return self.dataList[section].elements.count
    }

    func tableNode(_ tableNode: ASTableNode, nodeForRowAt indexPath: IndexPath) -> ASCellNode {
        guard let entity = self.dataList.element(at: indexPath) else {return ASCellNode()}
        let cell = TitleCell()
        cell.titleLabel.attributedText = NSAttributedString(string: entity.title, attributes: [.font: UIFont.systemFont(ofSize: 17)])
        cell.neverShowPlaceholders = true
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.dataList[section].title
    }

    func diffArray<SectionContainer>(array: RXCDiffArray<SectionContainer>, didChange difference: RDADifference<SectionContainer.Element, SectionContainer.Element.SubElementContainer.Element>) where SectionContainer : RangeReplaceableCollection, SectionContainer.Element : SectionElementProtocol {

        objc_sync_enter(self.tableView)
        tableView.reload(with: difference, animations: RDAReloadAnimations.automatic(), completion: nil)
        objc_sync_exit(self.tableView)

    }

    @objc func addSection() {
        let cards:[Card] = Card.random()
        self.dataList.modifyPrint {
            print("追加 \(cards.count) 节")
            self.dataList.rda_appendSection(contentsOf: cards)
        }
    }

    @objc func insertSection() {
        let section:Int = self.dataList.randomSection()
        let cards:[Card] = Card.random()
        self.dataList.modifyPrint {
            print("插入\(cards.count)节 @ \(section)")
            self.dataList.rda_insertSection(contentsOf: cards, at: section)
        }

    }

    @objc func deleteSection() {
        if self.dataList.isEmpty {return}
        let section = self.dataList.randomSection()
        self.dataList.modifyPrint {
            print("删除1节 @ \(section)")
            self.dataList.rda_removeSection(at: section)
        }
    }

    @objc func replaceSection() {
        if self.dataList.isEmpty {return}
        let cards:[Card] = Card.random()
        let section1 = self.dataList.randomSection()
        let section2 = self.dataList.randomSection()
        self.dataList.modifyPrint {
            print("替换 \(cards.count) 节 @ \(section1..<section2)")
            self.dataList.rda_replaceSection(section1..<section2, with: cards)
        }
    }

    @objc func moveSection() {
        if self.dataList.isEmpty {return}
        let section = self.dataList.randomSection()
        let target = Int.random(in: self.dataList.startIndex..<self.dataList.endIndex)
        self.dataList.modifyPrint {
            print("移动\(section)节 -> \(target)")
            self.dataList.rda_moveSection(from: section, to: target)
        }
    }

    @objc func addRow() {
        if self.dataList.isEmpty {return}
        let set = Entity.random()
        let section = self.dataList.randomSection()
        self.dataList.modifyPrint {
            print("追加\(set) @ \(section)")
            self.dataList.rda_appendRow(contentsOf: set, in: section)
        }
    }

    @objc func insertRow() {
        if self.dataList.isEmpty {return}
        let set = Entity.random()
        let section = self.dataList.randomSection()
        let row = self.dataList.randomRow(in: section)
        self.dataList.modifyPrint {
            print("插入\(set.count)个数据 @ \(section):\(row)")
            self.dataList.rda_insertRow(contentsOf: set, at: row, in: section)
        }
    }

    @objc func deleteRow() {
        if self.dataList.isEmpty {return}
        let section = self.dataList.randomSection()
        if self.dataList[section].elements.isEmpty {
            print("空节")
            return
        }
        let row = self.dataList.randomRow(in: section)
        self.dataList.modifyPrint {
            print("删除 @ \(section):\(row)")
            self.dataList.rda_removeRow(at: row, in: section, userInfo: nil)
        }
    }

    @objc func replaceRow() {
        if self.dataList.isEmpty {return}
        let section = self.dataList.randomSection()
        let rowCount = self.dataList[section].elements.count
        if self.dataList[section].elements.count == 0 {
            print("空节")
            return
        }
        let set = Entity.random(countRange: 1..<rowCount+1)
        let lower = Int.random(in: 0..<rowCount)
        let upper = Int.random(in: lower..<rowCount)
        self.dataList.modifyPrint {
            print("替换数据 @ \(section) range: \(lower..<upper) with \(set)")
            self.dataList.rda_replaceRow(lower..<upper, with: set, in: section)
        }
    }

    @objc func moveRow() {
        if self.dataList.isEmpty {return}
        let fromSection = self.dataList.randomSection()
        if self.dataList[fromSection].elements.isEmpty {
            print("空数据")
            return
        }
        let fromRow = self.dataList.randomRow(in: fromSection)
        let toSection = self.dataList.randomSection()
        let toRow = self.dataList.randomRow(in: toSection)
        self.dataList.modifyPrint {
            print("移动 \(fromSection):\(fromRow) -> \(toSection):\(toRow)")
            self.dataList.rda_moveRow(fromRow: fromRow, fromSection: fromSection, toRow: toRow, toSection: toSection)
        }
    }

    @objc func exchangeRow() {
        if self.dataList.isEmpty {return}
        let from = Int.random(in: 0..<self.dataList.count)
        let to = Int.random(in: 0..<self.dataList.count)
        print("交换\(from) with \(to)")
        //        let changes = self.dataList.exchange(index1: from, index2: to)
        //        self.dataListChanged(changes: changes)
    }

    @objc func reload() {
        self.tableView.reloadData()
    }

    @objc func printDataSource() {
        print(self.dataList.contentDescription)
    }

    @objc func test() {

        
    }

}

#endif
