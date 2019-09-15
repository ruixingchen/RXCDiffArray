//
//  ViewController.swift
//  RXCDiffArrayExample
//
//  Created by ruixingchen on 9/6/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import UIKit
import DifferenceKit

class Entity: Differentiable, CustomStringConvertible {

    var id:String = UUID().uuidString
    var title:String = ""

    typealias DifferenceIdentifier = String

    var differenceIdentifier: DifferenceIdentifier {return self.id}

    func isContentEqual(to source: Entity) -> Bool {
        return self.id == source.id
    }

    var description: String {return self.title}

}

class Card: Entity {

    var cardId:String = UUID().uuidString
    var elements:[Entity] = []

    override var differenceIdentifier: DifferenceIdentifier {
        return self.cardId
    }

    override func isContentEqual(to source: Entity) -> Bool {
        guard let card = source as? Card else {return false}
        return self.cardId == card.cardId
    }

    override var description: String {return self.elements.description}

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
    let bottomToolBar1 = UIToolbar()

    @objc func injected() {
        print("injected")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.dataList.threadSafe = true
        self.dataList.delegate = self
        self.dataList[0].title = "第一节"

        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 88, right: 0)
        self.view.addSubview(self.tableView)
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.reloadData()

        var navItems:[UIBarButtonItem] = []
        navItems.append(UIBarButtonItem(title: "add", style: .plain, target: self, action: #selector(addSection)))
        navItems.append(UIBarButtonItem(title: "insert", style: .plain, target: self, action: #selector(insertSection)))
        navItems.append(UIBarButtonItem(title: "delete", style: .plain, target: self, action: #selector(deleteSection)))
        navItems.append(UIBarButtonItem(title: "replace", style: .plain, target: self, action: #selector(replaceSection)))
        navItems.append(UIBarButtonItem(title: "move", style: .plain, target: self, action: #selector(moveSection)))
        self.navigationItem.leftBarButtonItems = navItems

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

    func randomEntities(countRange:Range<Int>=1..<3, valueRange:Range<Int>=0..<10)->[Entity] {
        if countRange.isEmpty {return []}
        let count = Int.random(in: countRange)
        let entities:[Entity] = (0..<count).map({_ in
            let number = Int.random(in: valueRange)
            let entity = Entity()
            entity.title = number.description
            return entity
        })
        return entities
    }

    func randomCards(countRange:Range<Int>=1..<3)->[Card] {
        if countRange.isEmpty {return []}
        let count = Int.random(in: countRange)
        let cards = (0..<count).map { (_) -> Card in
            let card = Card()
            card.elements = self.randomEntities(countRange: 1..<3)
            return card
        }
        return cards
    }

    func randomSection()->Int {
        if self.dataList.count < 1 {return 0}
        return Int.random(in: 0..<self.dataList.count)
    }

    func randomRow(in s:Int)->Int {
        if self.dataList[s].elements.count < 1 {return 0}
        return Int.random(in: 0..<self.dataList[s].elements.count)
    }

    func dataListDescription()->String {
        var sections:[[String]] = []
        for section in self.dataList {
            let rows:[String] = section.elements.map({$0.title})
            sections.append(rows)
        }
        return sections.description
    }

    func modifyPrint(batch:()->Void) {
        print("修改前: \(self.dataListDescription())")
        batch()
        print("修改后: \(self.dataListDescription())")
    }

    @objc func addSection() {
        let cards = self.randomCards()
        self.modifyPrint {
            print("追加 \(cards.count) 节")
            self.dataList.rda_appendSection(contentsOf: cards)
        }
    }

    @objc func insertSection() {
        let section:Int
        if self.dataList.isEmpty {
            section = 0
        }else {
            section = Int.random(in: 0..<self.dataList.count)
        }
        let cards = self.randomCards()
        self.modifyPrint {
            print("插入\(cards.count)节 @ \(section)")
            self.dataList.rda_insertSection(contentsOf: cards, at: section)
        }

    }

    @objc func deleteSection() {
        if self.dataList.count == 0 {
            return
        }
        let section = self.randomSection()
        self.modifyPrint {
            print("删除1节 @ \(section)")
            self.dataList.rda_removeSection(at: section)
        }
    }

    @objc func replaceSection() {
        if self.dataList.isEmpty {return}
        let section = self.randomSection()
        let card = self.randomCards(countRange: 1..<2).first!
        self.modifyPrint {
            print("替换1节 @ \(section)")
            self.dataList.rda_replaceSection(at: section, with: card)
        }

    }

    @objc func moveSection() {
        if self.dataList.isEmpty {return}
        let section = self.randomSection()
        let target = Int.random(in: self.dataList.startIndex..<self.dataList.endIndex)
        self.modifyPrint {
            print("移动\(section)节 -> \(target)")
            self.dataList.rda_moveSection(from: section, to: target)
        }
    }

    @objc func addRow() {
        let set = self.randomEntities()
        let section = self.randomSection()
        self.modifyPrint {
            print("追加\(set) @ \(section)")
            self.dataList.rda_appendRow(contentsOf: set, in: section)
        }
    }

    @objc func insertRow() {
        let set = self.randomEntities()
        let section = self.randomSection()
        let row = self.randomRow(in: section)
        self.modifyPrint {
            print("插入\(set.count)个数据 @ \(section):\(row)")
            self.dataList.rda_insertRow(contentsOf: set, at: row, in: section)
        }
    }

    @objc func deleteRow() {
        let section = self.randomSection()
        if self.dataList[section].elements.isEmpty {
            print("空节")
            return
        }
        let row = self.randomRow(in: section)
        self.modifyPrint {
            print("删除 @ \(section):\(row)")
            self.dataList.rda_removeRow(at: row, in: section, userInfo: nil)
        }
    }

    @objc func replaceRow() {
        let section = self.randomSection()
        let rowCount = self.dataList[section].elements.count
        if self.dataList[section].elements.count == 0 {
            print("空节")
            return
        }
        let set = self.randomEntities(countRange: 1..<rowCount+1)
        let lower = Int.random(in: 0..<rowCount)
        let upper = Int.random(in: lower..<rowCount)
        self.modifyPrint {
            print("替换数据 @ \(section) range: \(lower..<upper) with \(set)")
            self.dataList.rda_replaceRow(lower..<upper, with: set, in: section)
        }
    }

    @objc func moveRow() {
        let fromSection = self.randomSection()
        if self.dataList[fromSection].elements.isEmpty {
            print("空数据")
            return
        }
        let fromRow = self.randomRow(in: fromSection)
        let toSection = self.randomSection()
        let toRow = self.randomRow(in: toSection)
        self.modifyPrint {
            print("移动 \(fromSection):\(fromRow) -> \(toSection):\(toRow)")
            self.dataList.rda_moveRow(fromRow: fromRow, fromSection: fromSection, toRow: toRow, toSection: toSection)
        }
    }

    @objc func exchangeRow() {
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
        print(self.dataListDescription())
    }

    @objc func test() {

        self.dataList.delegate = nil

        let ui:[AnyHashable:Any] = [RXCDiffArray<[Card]>.Key.notify: false]
        let cycle = 10
        let count = 10000

        if true {
            var dkScores:[TimeInterval] = []
            for i in 0..<cycle {
                self.dataList.rda_removeAllRow(where: {_ in true})
                let entities = self.randomEntities(countRange: count..<count+1)
                self.dataList.rda_appendRow(contentsOf: entities, in: 0)
                let start = Date().timeIntervalSince1970

                let diff = self.dataList.batchWithDifferenceKit {
                    self.dataList.rda_removeAllRow(userInfo:ui, where: {Int($0.title)! > 5})
                }

                dkScores.append(Date().timeIntervalSince1970-start)
                print("DK \(i)")
            }
            print(dkScores)
            print(dkScores.reduce(0, {$0+$1})/Double(cycle))
        }

        if true {
            var scores:[TimeInterval] = []
            for i in 0..<cycle {
                self.dataList.rda_removeAllRow(where: {_ in true})
                let entities = self.randomEntities(countRange: count..<count+1)
                self.dataList.rda_appendRow(contentsOf: entities, in: 0)
                let start = Date().timeIntervalSince1970

                self.dataList.rda_removeAllRow(where: {Int($0.title)! > 5})
                scores.append(Date().timeIntervalSince1970-start)
                print("RDA \(i)")
            }
            print(scores)
            print(scores.reduce(0, {$0+$1})/Double(cycle))
        }
    }

}



