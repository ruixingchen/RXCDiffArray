//
//  ViewController.swift
//  Example
//
//  Created by ruixingchen on 10/30/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import UIKit
import RXCDiffArray

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

extension SimpleCard: RDASectionElementProtocol {

    var rda_elements: [Any] {
        get {return self.elements}
        set {self.elements = newValue as! [Int]}
    }

}

func generateRandomNum(numRange:Range<Int>, quantityRange:Range<Int>)->[Int] {
    var arr:[Int] = []
    for _ in 0..<(quantityRange.randomElement() ?? 0) {
        arr.append(numRange.randomElement() ?? -1)
    }
    return arr
}

class ViewController: UITableViewController {

    let dataSource:RXCDiffArray2<[SimpleCard]> = RXCDiffArray2.init()

    override func viewDidLoad() {
        super.viewDidLoad()

        for _ in (0..<3) {
            let card = SimpleCard()
            card.elements = generateRandomNum(numRange: 1..<9, quantityRange: 1..<5)
            self.dataSource.add(card)
        }

        let diff = self.dataSource.removeAllRow(in: 1..<2, where: {($0 as! Int) > 0})
        print(diff)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.dataSource.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource[section].elements.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = self.dataSource[indexPath.section].elements[indexPath.row].description
        return cell
    }

}

