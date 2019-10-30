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

protocol Entity {
    var entityType:String {get}
}

protocol Card: Entity {

    var entities:[Entity] {get}

}

class SimpleEntity:Entity {

    var entityType: String = ""

}

class SimpleCard {

    var entityType: String = "card"

    var elements: [Int] = []

}

extension SimpleCard: RDASectionElementProtocol, RDADiffableSectionElementProtocol {

    var rda_elements: [Any] {
        get {return self.elements}
        set {self.elements = newValue as! [Int]}
    }

    var rda_diffIdentifier: AnyHashable {return self.entityType}

    var rda_diffableElements: [RDADiffableRowElementProtocol] {return self.elements}

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

    let dataSource:RXCDiffArray<[SimpleCard]> = RXCDiffArray()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self
        self.tableView.delegate = self

        measureTime(identifier: "添加数据") {
            for i in (1..<4) {
                let card = SimpleCard()
                //card.entityType = (0...100000).randomElement()!.description
                card.elements = generateRandomNum(numRange: 0..<10, quantityRange: 3..<10)
                self.dataSource.add(card)
            }
        }

    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.dataSource.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource[section].elements.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = self.dataSource[indexPath.section].elements[indexPath.row].description
        return cell
    }

    @IBAction func didTapAddSection(_ sender: Any) {
        let card = SimpleCard()
        //card.entityType = UnicodeScalar((0x0030...0x0039).randomElement()!)!.description
        card.elements = generateRandomNum(numRange: 0..<10, quantityRange: 3..<10)
        let diff = self.dataSource.batchWithDifferenceKit_2D {
            self.dataSource.add(card)
        }
        print(diff)
        for i in diff {
            self.tableView!.reload(with: i, animations: .automatic(), batch: true, reloadDataSource: { (newData) in
                if let data = newData {
                    self.dataSource.removeAll(userInfo: ["notify": false], where: {_ in true})
                    self.dataSource.add(contentsOf: data, userInfo: ["notify": false])
                }
            }, completion: nil)
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
        let diff = self.dataSource.batchWithDifferenceKit_2D {
            self.dataSource.addRow(contentsOf: elements, in: 1, userInfo: ["notify":false])
        }
        print(diff)
        for i in diff {
            self.tableView!.reload(with: i, animations: .automatic(), batch: true, reloadDataSource: { (newData) in
                if let data = newData {
                    self.dataSource.removeAll(userInfo: ["notify": false], where: {_ in true})
                    self.dataSource.add(contentsOf: data, userInfo: ["notify": false])
                }
            }, completion: nil)
        }
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

