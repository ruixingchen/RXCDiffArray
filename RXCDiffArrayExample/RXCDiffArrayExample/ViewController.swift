//
//  ViewController.swift
//  RXCDiffArrayExample
//
//  Created by ruixingchen on 9/6/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let dataList:RXCDiffArray<Int> = RXCDiffArray()

    let tableView:UITableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.dataList.threadSafe = true
        self.view.addSubview(self.tableView)
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.reloadData()

        let changes = self.dataList.add(contentsOf: [0,1,2,3])
        //self.dataListChanged(changes: changes)

        let addButton = UIBarButtonItem(title: "add", style: .plain, target: self, action: #selector(addRandomly))
        let insertButton = UIBarButtonItem(title: "insert", style: .plain, target: self, action: #selector(insertRandomly))
        let deleteButton = UIBarButtonItem(title: "delete", style: .plain, target: self, action: #selector(deleteRandomly))
        let replaceButton = UIBarButtonItem(title: "replace", style: .plain, target: self, action: #selector(replaceRandomly))
        let moveButton = UIBarButtonItem(title: "move", style: .plain, target: self, action: #selector(moveRandomly))
        let exchangeButton = UIBarButtonItem(title: "exchange", style: .plain, target: self, action: #selector(exchangeRandomly))
        //let reloadButton = UIBarButtonItem(title: "reload", style: .plain, target: self, action: #selector(reload))
        self.navigationItem.leftBarButtonItems = [addButton, insertButton, deleteButton]
        self.navigationItem.rightBarButtonItems = [exchangeButton, moveButton, replaceButton]
    }

    func generateRandomSet(numRange:Range<Int>=0..<6, valueRange:Range<Int>=0..<10)->[Int] {
        var add:[Int] = []
        for _ in 0..<Int.random(in: numRange.lowerBound..<numRange.upperBound) {
            add.append(Int.random(in: valueRange.lowerBound..<valueRange.upperBound))
        }
        return add
    }

    @objc func addRandomly() {
        let add = self.generateRandomSet()
        let changes = self.dataList.add(contentsOf: add)
        self.dataListChanged(changes: changes)
    }

    @objc func insertRandomly() {
        let add = self.generateRandomSet()
        let index = Int.random(in: 0..<self.dataList.count)
        let changes = self.dataList.insert(contentOf: add, at: index)
        self.dataListChanged(changes: changes)
    }

    @objc func deleteRandomly() {
        guard !self.dataList.isEmpty else {return}
        let index = Int.random(in: 0..<self.dataList.count)
//        let changes = self.dataList.remove(at: index)
//        self.dataListChanged(changes: changes)
    }

    @objc func replaceRandomly() {
        let index = Int.random(in: 0..<self.dataList.count)
        let add = Int.random(in: 0..<9)
//        let changes = self.dataList.replace(at: index, with: add)
//        self.dataListChanged(changes: changes)
    }

    @objc func moveRandomly() {
        let from = Int.random(in: 0..<self.dataList.count)
        let to = Int.random(in: 0..<self.dataList.count)
        print("move \(from) to \(to)")
//        let changes = self.dataList.move(from: from, to: to)
//        self.dataListChanged(changes: changes)
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
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let from = 0
        let to = 2
        print("move \(from) to \(to)")
//        let changes = self.dataList
//        self.dataListChanged(changes: changes)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        cell?.textLabel?.text = self.dataList[indexPath.row].description
        return cell!
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.reloadData()
    }

    func dataListChanged(changes:RDAChangeSet<Int>) {
//        self.tableView.performBatchUpdates({
//            for i in changes {
//                switch i {
//                case .move(let move):
//                    self.tableView.moveRow(at: IndexPath(row: move.fromIndex, section: 0), to: IndexPath(row: move.toIndex, section: 0))
//                case .insert(let insert):
//                    self.tableView.insertRows(at: [IndexPath(row: insert.index, section: 0)], with: .automatic)
//                case .delete(let delete):
//                    self.tableView.deleteRows(at: [IndexPath(row: delete.index, section: 0)], with: .automatic)
//                case .replace(let replace):
//                    self.tableView.reloadRows(at: [IndexPath(row: replace.index, section: 0)], with: .automatic)
//                }
//            }
//        }) { (_) in
//            print("更新结束")
//        }

    }

}

