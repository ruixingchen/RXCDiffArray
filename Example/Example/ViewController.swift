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

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!

    let dataSource:RXCDiffArray<[SimpleCard]> = RXCDiffArray()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self
        self.tableView.delegate = self

        for _ in (0..<3) {
            let card = SimpleCard()
            card.elements = generateRandomNum(numRange: 1..<9, quantityRange: 2..<5)
            self.dataSource.add(card)
        }

        if true {
            let diff = self.dataSource.batchWithDifferenceKit_2D {
                self.dataSource.removeRow(at: 1, in: 1)
            }
            print(diff)
        }

        let a:RXCDiffArray<[Int]> = RXCDiffArray(elements: [0,1,2,3,4,5])
        let diff = a.batchWithDifferenceKit_1D {
            a.removeAll(where: {$0 < 3})
        }
        print(diff)
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

