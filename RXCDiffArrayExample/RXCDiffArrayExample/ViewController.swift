//
//  ViewController.swift
//  RXCDiffArrayExample
//
//  Created by ruixingchen on 9/6/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, RXCDiffArrayDelegate {

    private(set) var dataList:RXCDiffArray<[Card]>!

    let tableView:UITableView = UITableView(frame: CGRect.zero, style: .grouped)

    @objc func injected() {
        print("injected")
    }

    func initDataList() {
        var cards:[Card] = []
        cards.append({
            let card = Card()
            let entity = Entity()
            entity.title = "TableView"
            entity.entityType = "tableview"
            card.elements = [entity]
            return card
        }())
        cards.append({
            let card = Card()
            let entity = Entity()
            entity.title = "CollectionView"
            entity.entityType = "collectionview"
            card.elements = [entity]
            return card
        }())
        cards.append({
            let card = Card()
            let entity = Entity()
            entity.title = "ASTableNode"
            entity.entityType = "tablenode"
            card.elements = [entity]
            return card
        }())
        cards.append({
            let card = Card()
            let entity = Entity()
            entity.title = "ASCollectionNode"
            entity.entityType = "collectionnode"
            card.elements = [entity]
            return card
        }())
        self.dataList = RXCDiffArray.init(elements: cards)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.initDataList()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initDataList()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "RXCDiffArray"

        self.dataList.threadSafe = true
        self.dataList.delegate = self

        self.view.addSubview(self.tableView)
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.reloadData()

    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.tableView.frame = self.view.frame
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
        cell?.textLabel?.text = element?.title
        return cell!
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let entity = self.dataList.element(at: indexPath) else {return}
        let vc:UIViewController
        switch entity.entityType {
        case "tableview":
            vc = TableViewExampleViewController()
        case "collectionview":
            vc = TableViewExampleViewController()
        case "tablenode":
            vc = ASTableNodeExampleViewController()
        case "collectionnode":
            vc = TableViewExampleViewController()
        default:
            vc = UIViewController()
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.dataList[section].title
    }

    func diffArray<SectionContainer>(array: RXCDiffArray<SectionContainer>, didChange difference: RDADifference<SectionContainer.Element, SectionContainer.Element.SubElementContainer.Element>) where SectionContainer : RangeReplaceableCollection, SectionContainer.Element : SectionElementProtocol {

        objc_sync_enter(self.tableView)
        tableView.reload(with: difference, animations: RDAReloadAnimations.automatic(), completion: nil)
        objc_sync_exit(self.tableView)

    }
}
