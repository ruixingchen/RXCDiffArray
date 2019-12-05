//
//  ViewController.swift
//  Example
//
//  Created by ruixingchen on 10/30/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import UIKit
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

class SimpleSection: RDASectionElementProtocol, RDADiffableSectionElementProtocol {

    let title:String

    init(title:String) {
        self.title = title
    }

    var rowElements:[SimpleRow] = []

    var rda_elements: [Any] {
        get {return self.rowElements}
        set {self.rowElements = newValue as! [SimpleRow]}
    }

    var rda_diffableElements: [RDADiffableRowElementProtocol] {return self.rda_elements as! [RDADiffableRowElementProtocol]}

    var rda_diffIdentifier: AnyHashable {return self.title}
}

class SimpleRow: RDADiffableRowElementProtocol {

    let title:String

    init(title:String) {
        self.title = title
    }

    var rda_diffIdentifier: AnyHashable {return self.title}
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, RXCDiffArrayDelegate {

    @IBOutlet weak var tableView: UITableView!

    let dataSource:RXCDiffArray<[SimpleSection]> = RXCDiffArray()

    deinit {
        print("deinit")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.dataSource.addDelegate(self)
        self.dataSource.add(SimpleSection(title: "0"), userInfo: [RXCDiffArrayKey.notify: false])
        self.dataSource.addRow(contentsOf: [SimpleRow(title: "0"),SimpleRow(title: "1"),SimpleRow(title: "2")], in: 0, userInfo: [RXCDiffArrayKey.notify: false])
        self.tableView.reloadData()
    }

    func diffArray<ElementContainer>(diffArray: RXCDiffArray<ElementContainer>, didModifiedWith differences: [RDADifference<ElementContainer.Element>]) where ElementContainer : RangeReplaceableCollection, ElementContainer.Index == Int {
        self.tableView.reload(with: differences, animations: RDATableViewAnimations.none(), reloadDataSource: { (newDataSource) in
            self.dataSource.removeAll(userInfo: [RXCDiffArrayKey.notify: false], where: {_ in true})
            self.dataSource.add(contentsOf: newDataSource as! [SimpleSection],userInfo: [RXCDiffArrayKey.notify: false])
        }, completion: nil)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.dataSource.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource[section].rowElements.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = self.dataSource[indexPath.section].rowElements[indexPath.row].title
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.dataSource[section].title
    }

    @IBAction func didTapAddSection(_ sender: Any) {
        let section = SimpleSection(title: self.dataSource.count.description)
        section.rowElements = generateRandomNum(numRange: 0..<100, quantityRange: 1..<6).map({SimpleRow(title: $0.description)})
        self.dataSource.add(section)
    }

    @IBAction func didTapRemoveSection(_ sender: Any) {
        if let section = (0..<self.dataSource.count).randomElement() {
            self.dataSource.remove(at: section)
        }
    }

    @IBAction func didTapInsertSection(_ sender: Any) {
        let index = (0..<self.dataSource.count).randomElement() ?? 0
        self.dataSource.insert(self.makeSection(), at: index)
    }

    @IBAction func didTapUpdateSection(_ sender: Any) {
        guard let index = (0..<self.dataSource.count).randomElement() else {return}
        self.dataSource.replace(at: index, with: self.makeSection())
    }

    @IBAction func didTapMoveSection(_ sender: Any) {
        guard let index1 = (0..<self.dataSource.count).randomElement() else {return}
        guard let index2 = (0..<self.dataSource.count).randomElement() else {return}
        self.dataSource.move(from: index1, to: index2)
    }

    @IBAction func didTapAddRow(_ sender: Any) {
        if let section = self.randomSectionIndex() {
            self.dataSource.addRow(SimpleRow(title: (0..<100).randomElement()!.description), in: section)
        }
    }

    @IBAction func didTapRemoveRow(_ sender: Any) {
        if let section = self.randomSectionIndex(), let row = self.randomRowIndex(in: section) {
            self.dataSource.removeRow(at: row, in: section)
        }
    }

    @IBAction func didTapInsertRow(_ sender: Any) {
        if let section = self.randomSectionIndex() {
            let row = self.randomRowIndex(in: section) ?? 0
            self.dataSource.insertRow(SimpleRow(title: (0..<100).randomElement()!.description), at: row, in: section)
        }
    }

    @IBAction func didTapUpdateRow(_ sender: Any) {
        if let section = self.randomSectionIndex(), let row = self.randomRowIndex(in: section) {
            self.dataSource.replaceRow(at: row, in: section, with: SimpleRow(title: (0..<100).randomElement()!.description))
        }
    }

    @IBAction func didTapMoveRow(_ sender: Any) {
        if let section1 = self.randomSectionIndex(), let row1 = self.randomRowIndex(in: section1),let section2 = self.randomSectionIndex(), let row2 = self.randomRowIndex(in: section2) {
            self.dataSource.moveRow(fromRow: row1, fromSection: section1, toRow: row2, toSection: section2)
        }
    }

    @IBAction func didTapReBuild(_ sender: Any) {
        let diff = self.dataSource.batchWithDifferenceKit_2D {
            self.dataSource.removeAll(userInfo: [RXCDiffArrayKey.notify: false], where: {_ in true})
            let section = self.makeSection()
            self.dataSource.add(section, userInfo: [RXCDiffArrayKey.notify: false])
        }
        print(diff.count)
        self.diffArray(diffArray: self.dataSource, didModifiedWith: diff)
    }


}

extension ViewController {

    func makeSection()->SimpleSection {
        let section = SimpleSection(title: self.dataSource.count.description)
        section.rowElements = generateRandomNum(numRange: 0..<100, quantityRange: 1..<6).map({SimpleRow(title: $0.description)})
        return section
    }

    func makeRows()->[SimpleRow] {
        return generateRandomNum(numRange: 0..<100, quantityRange: 1..<6).map({SimpleRow(title: $0.description)})
    }

    func randomSectionIndex()->Int? {
        return (0..<self.dataSource.count).randomElement()
    }

    func randomRowIndex(in section:Int)->Int? {
        return (0..<self.dataSource[section].rowElements.count).randomElement()
    }

}
