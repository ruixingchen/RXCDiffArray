//
//  ViewController.swift
//  Example
//
//  Created by ruixingchen on 10/30/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import UIKit
import RXCDiffArray
import DifferenceKit

extension String: Differentiable {}
extension Int: Differentiable {}

extension Int: RDADiffableRowElementProtocol {
    public var rda_diffIdentifier: AnyHashable {return self}
}

func generateRandomNum(numRange:Range<Int>, quantityRange:Range<Int>)->[Int] {
    var arr:[Int] = []
    for _ in 0..<(quantityRange.randomElement() ?? 0) {
        arr.append(numRange.randomElement() ?? -1)
    }
    return arr
}

func measureTime(identifier:String, closure:()->Void) {
    let start = Date().timeIntervalSince1970
    closure()
    let time = Date().timeIntervalSince1970 - start
    print("\(identifier)结束, 耗时: \(String.init(format: "%.4f", time))")
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!

    let dataSource:RXCDiffArray<[Entity]> = RXCDiffArray()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self
        self.tableView.delegate = self

        measureTime(identifier: "添加数据") {
            for _ in (1..<4) {
                let entities = generateRandomNum(numRange: 0..<10, quantityRange: 3..<10).map({ (num) -> SimpleEntity in
                    let entity = SimpleEntity()
                    entity.entityType = num.description
                    return entity
                })
                self.dataSource.add(contentsOf: entities)
            }
        }

    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.dataSource.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = self.dataSource[indexPath.section].entityType
        return cell
    }

    @IBAction func didTapAddSection(_ sender: Any) {
        let card = SimpleCard()
        card.entities = generateRandomNum(numRange: 0..<100000, quantityRange: 1..<10).map({let e=SimpleEntity();e.entityType=$0.description;return e})
        
        let ds:RXCDiffArray<[EntityWrapper]> = RXCDiffArray(elements: self.dataSource.map({EntityWrapper(entity: $0)}))

        let diff = ds.batchWithDifferenceKit_1D {
            ds.add(contentsOf: card.entities.map({$0.wrappedEntity()}))
        }

        for i in diff {
            self.tableView.reload(withDifference_1D_toSection: i, animations: .automatic(), reloadDataSource: { (newData) in
                self.dataSource.removeAll(userInfo: ["notify": false], where: {_ in true})
                let newDataUnwrapped = newData.map({$0.unwrappedEntity()})
                self.dataSource.add(contentsOf: newDataUnwrapped, userInfo: ["notify": false])
            }, completion: nil)
//            self.tableView!.reload(with: i, animations: .automatic(), reloadDataSource: { (newData) in
//                self.dataSource.removeAll(userInfo: ["notify": false], where: {_ in true})
//                let newDataUnwrapped = newData.map({$0.unwrappedEntity()})
//                self.dataSource.add(contentsOf: newDataUnwrapped, userInfo: ["notify": false])
//            }, completion: nil)
        }
    }

    @IBAction func didTapRemoveSection(_ sender: Any) {

    }

    @IBAction func didTapInsertSection(_ sender: Any) {
        
    }

    @IBAction func didTapUpdateSection(_ sender: Any) {

    }

    @IBAction func didTapMoveSection(_ sender: Any) {

    }

    @IBAction func didTapAddRow(_ sender: Any) {
        let elements = generateRandomNum(numRange: 0..<10, quantityRange: 3..<10)
//        let diff = self.dataSource.batchWithDifferenceKit_2D {
//            self.dataSource.addRow(contentsOf: elements, in: 1, userInfo: ["notify":false])
//        }
//        for i in diff {
//            self.tableView!.reload(with: i, animations: .automatic(), reloadDataSource: { (newData) in
//                self.dataSource.removeAll(userInfo: ["notify": false], where: {_ in true})
//                self.dataSource.add(contentsOf: newData, userInfo: ["notify": false])
//            }, completion: nil)
//        }
    }

    @IBAction func didTapRemoveRow(_ sender: Any) {

    }

    @IBAction func didTapInsertRow(_ sender: Any) {

    }

    @IBAction func didTapUpdateRow(_ sender: Any) {

    }

    @IBAction func didTapMoveRow(_ sender: Any) {

    }

}

protocol RootProtocol {

}

protocol SubProtocol: RootProtocol {

}

extension Array where Element == RootProtocol {
    func printRoot() {
        print("root")
    }
}

extension Array where Element: RootProtocol {
    func printRoot2() {
        print("root2")
    }
}

extension Array where Element == SubProtocol {
    func printSub() {
        print("sub")
    }
}

extension Array where Element: SubProtocol {
    func printSub2() {
        print("sub2")
    }
}
