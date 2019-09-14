//
//  ViewController.swift
//  RXCDiffArrayExample
//
//  Created by ruixingchen on 9/6/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import UIKit
import DifferenceKit

class Entity: Differentiable {

    var id:String = ""
    var title:String = ""

    typealias DifferenceIdentifier = String

    var differenceIdentifier: DifferenceIdentifier {return self.id}

    func isContentEqual(to source: Entity) -> Bool {
        return self.id == source.id
    }

}

class Card: Entity {

    var cardId:String = ""
    var elements:[Entity] = []

    override var differenceIdentifier: DifferenceIdentifier {
        return self.cardId
    }

    override func isContentEqual(to source: Entity) -> Bool {
        guard let card = source as? Card else {return false}
        return self.cardId == card.cardId
    }

}

extension Card: SectionElementProtocol {
    typealias SubElementContainer = Array<Entity>

    var rda_elements: Array<Entity> {get {return elements} set{self.elements = newValue} }
}

extension String: Differentiable {}
extension Int : Differentiable {}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, RXCDiffArrayDelegate {

    let dataList:RXCDiffArray<[Card]> = RXCDiffArray.init(elements: [Card()])

    let tableView:UITableView = UITableView(frame: CGRect.zero, style: .grouped)
    let bottomToolBar = UIToolbar()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.dataList.threadSafe = true
        self.dataList.delegate = self
        self.dataList[0].title = "第一节"

        self.view.addSubview(self.tableView)
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.reloadData()

        self.view.addSubview(self.bottomToolBar)
        var toolBarItems:[UIBarButtonItem] = []
        toolBarItems.append(UIBarButtonItem(title: "Reload", style: .plain, target: self, action: #selector(reload)))
        self.bottomToolBar.items = toolBarItems

        var navItems:[UIBarButtonItem] = []
        navItems.append(UIBarButtonItem(title: "add", style: .plain, target: self, action: #selector(addRandomly)))
        navItems.append(UIBarButtonItem(title: "insert", style: .plain, target: self, action: #selector(insertRandomly)))
        navItems.append(UIBarButtonItem(title: "delete", style: .plain, target: self, action: #selector(deleteRandomly)))
        navItems.append(UIBarButtonItem(title: "replace", style: .plain, target: self, action: #selector(replaceRandomly)))
        navItems.append(UIBarButtonItem(title: "move", style: .plain, target: self, action: #selector(moveRandomly)))
        self.navigationItem.leftBarButtonItems = navItems
    }

    func generateRandomEntities(countRange:Range<Int>=0..<6, valueRange:Range<Int>=0..<10)->[Entity] {
        let count = Int.random(in: countRange)
        let entities:[Entity] = (0..<count).map({_ in
            let number = Int.random(in: valueRange)
            let entity = Entity()
            entity.title = number.description
            return entity
        })
        return entities
    }

    func randomSection()->Int {
        if self.dataList.count < 1 {return 0}
        return Int.random(in: 0..<self.dataList.count)
    }

    func randomRow(in s:Int)->Int {
        if self.dataList[s].elements.count < 1 {return 0}
        return Int.random(in: 0..<self.dataList[s].elements.count)
    }

    @objc func addRandomly() {
        if false {
            let set = self.generateRandomEntities()
            let section = self.randomSection()
            print("追加\(set.count)个数据 @ \(section)")
            self.dataList.rda_appendRow(contentsOf: set, in: 0)
        }
        if true {
            let card = Card()
            card.elements = self.generateRandomEntities()
            if true {
                self.dataList.rda_appendSection(card)
            }
        }
    }

    @objc func insertRandomly() {
        let set = self.generateRandomEntities()
        let section = self.randomSection()
        let row = self.randomRow(in: section)
        print("插入\(set.count)个数据 @ \(section):\(row)")
        self.dataList.rda_insertRow(contentsOf: set, at: row, in: section)
    }

    @objc func deleteRandomly() {
        let section = self.randomSection()
        if self.dataList[section].elements.isEmpty {
            print("空节")
            return
        }
        let row = self.randomRow(in: section)
        print("删除 @ \(section):\(row)")
        self.dataList.rda_removeRow(at: row, in: section, userInfo: nil)
    }

    @objc func replaceRandomly() {
        if false {
            //替换单个
            let set = self.generateRandomEntities(countRange: 1..<2)
            let section = self.randomSection()
            if self.dataList[section].elements.isEmpty {
                print("空节")
                return
            }
            let row = self.randomRow(in: section)
            print("替换数据 @ \(section):\(row)")
            self.dataList.rda_replaceRow(at: row, in: section, with: set.first!)
        }

        if false {
            //范围替换
            let section = self.randomSection()
            let rowCount = self.dataList[section].elements.count
            if self.dataList[section].elements.count == 0 {
                print("空节")
                return
            }
            let set = self.generateRandomEntities(countRange: 1..<rowCount+1)
            let lower = Int.random(in: 0..<rowCount)
            let upper = Int.random(in: lower..<rowCount)
            print("替换数据 @ \(section) range: \(lower..<upper) with \(set.count)")
            self.dataList.rda_replaceRow(lower..<upper, with: set, in: section)
        }

        if true {
            if false {
                //删除
                let set:[Entity] = []
                self.dataList.rda_replaceRow(0..<2, with: set, in: 0)
            }
            if false {
                //新增
                let set = self.generateRandomEntities(countRange: 2..<3)
                self.dataList.rda_replaceRow(1..<1, with: set, in: 0)
            }
            if true {
                //随机

            }
        }

    }

    @objc func moveRandomly() {
        let fromSection = self.randomSection()
        if self.dataList[fromSection].elements.isEmpty {
            print("空数据")
            return
        }
        let fromRow = self.randomRow(in: fromSection)
        let toSection = self.randomSection()
        let toRow = self.randomRow(in: toSection)
        print("移动 \(fromSection):\(fromRow) -> \(toSection):\(toRow)")
        self.dataList.rda_moveRow(fromRow: fromRow, fromSection: fromSection, toRow: toRow, toSection: toSection)
    }

    @objc func exchangeRandomly() {
        let from = Int.random(in: 0..<self.dataList.count)
        let to = Int.random(in: 0..<self.dataList.count)
        print("交换\(from) with \(to)")
//        let changes = self.dataList.exchange(index1: from, index2: to)
//        self.dataListChanged(changes: changes)
    }

    @objc func reload() {
        self.tableView.reloadData()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.tableView.frame = self.view.frame
        self.bottomToolBar.frame = CGRect(x: 0, y: self.view.bounds.height-88, width: self.view.bounds.width, height: 88)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.dataList.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataList[section].elements.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        let element = self.dataList.element(at: indexPath)
        cell?.textLabel?.text = element.title
        return cell!
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.dataList[section].title
    }

    func diffArray<SectionContainer>(array: RXCDiffArray<SectionContainer>, didChange difference: RDADifference<SectionContainer.Element, SectionContainer.Element.SubElementContainer.Element>) where SectionContainer : RangeReplaceableCollection, SectionContainer.Element : SectionElementProtocol {

        objc_sync_enter(self.tableView)
        tableView.reload(with: difference, animations: UITableView.RDAReloadAnimations.automatic(), completion: nil)
        objc_sync_exit(self.tableView)

    }

}
