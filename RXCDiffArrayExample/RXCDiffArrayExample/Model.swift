//
//  Model.swift
//  RXCDiffArrayExample
//
//  Created by ruixingchen on 9/15/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import Foundation
import DifferenceKit

public class Entity: Differentiable, CustomStringConvertible {

    static func random(countRange:Range<Int>=1..<4, valueRange:Range<Int>=0..<20)->[Entity] {
        let count = countRange.isEmpty ? 0 : Int.random(in: countRange)
        return Entity.ramdom(count: count, valueRange: valueRange)
    }

    static func ramdom(count:Int, valueRange:Range<Int>=0..<20)->[Entity] {
        let entities:[Entity] = (0..<count).map({_ in
            let number = Int.random(in: valueRange)
            let entity = Entity()
            entity.title = number.description
            return entity
        })
        return entities
    }

    var id:String = UUID().uuidString
    var title:String = UUID().uuidString
    var entityType:String = ""

    public typealias DifferenceIdentifier = String

    public var differenceIdentifier: DifferenceIdentifier {return self.id}

    public func isContentEqual(to source: Entity) -> Bool {
        return self.id == source.id
    }

    public var description: String {return self.title}

}

public class Card: Entity {

    static func random(countRange:Range<Int>=1..<4, elementCountRange:Range<Int>=1..<4)->[Card] {
        let count = countRange.isEmpty ? 0 : Int.random(in: countRange)
        let elementCount = elementCountRange.isEmpty ? 0 : Int.random(in: elementCountRange)
        return Card.random(count: count, elementCount: elementCount)
    }

    static func random(count:Int, elementCount:Int)->[Card] {
        let cards = (0..<count).map { (_) -> Card in
            let card = Card()
            card.elements = Entity.random(countRange: elementCount..<elementCount+1)
            return card
        }
        return cards
    }

    var cardId:String = UUID().uuidString
    var elements:[Entity] = []
    var footerTitle:String?

    override public var differenceIdentifier: DifferenceIdentifier {
        return self.cardId
    }

    override public func isContentEqual(to source: Entity) -> Bool {
        guard let card = source as? Card else {return false}
        return self.cardId == card.cardId
    }

    override public var description: String {return self.elements.description}

}

extension Card: SectionElementProtocol {
    public typealias SubElementContainer = Array<Entity>

    public var rda_elements: Array<Entity> {get {return elements} set{self.elements = newValue} }
}

extension String: Differentiable {}
extension Int : Differentiable {}

extension RXCDiffArray where SectionIndex==Int, RowIndex==Int {

    func randomSection()->Int {
        if self.isEmpty {return 0}
        return Int.random(in: 0..<self.count)
    }

    func randomRow(in s:Int)->Int {
        if self[s].rda_elements.isEmpty {return 0}
        return Int.random(in: 0..<self[s].rda_elements.count)
    }

}

public extension RXCDiffArray where Element: Card, RowElement: Entity {

    var contentDescription: String {
        var sections:[[String]] = []
        for section in self {
            let rows:[String] = section.elements.map({$0.title})
            sections.append(rows)
        }
        return sections.description
    }

    func modifyPrint(batch:()->Void) {
        print("修改前: \(self.contentDescription)")
        batch()
        print("修改后: \(self.contentDescription)")
    }

}
