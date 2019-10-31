//
//  EntityWrapper.swift
//  Example
//
//  Created by ruixingchen on 10/31/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import Foundation
import RXCDiffArray

class EntityWrapper: Entity {
    var rda_diffIdentifier: AnyHashable {return self.entity.rda_diffIdentifier}

    var entity:Entity

    var entityType: String {return self.entity.entityType}

    init(entity:Entity) {
        self.entity = entity
    }

}

extension Entity {
    func wrappedEntity()->EntityWrapper {
        return EntityWrapper(entity: self)
    }

    func unwrappedEntity()->Entity {
        if let wrapper = self as? EntityWrapper {
            return wrapper.entity
        }
        return self
    }
}


class CardWrapper: Card {

    var entities: [Entity] {return self.card.entities}

    var entityType: String {return self.card.entityType}

    var rda_diffIdentifier: AnyHashable {return self.card.rda_diffIdentifier}

    var rda_diffableElements: [RDADiffableRowElementProtocol] {return self.card.rda_diffableElements}

    var rda_elements: [Any] {
        get {return self.card.rda_elements}
        set {self.card.rda_elements = newValue}
    }

    var card:Card

    init(card:Card) {
        self.card = card
    }

}

extension Card {

    func wrappedCard()->CardWrapper {
        return CardWrapper(card: self)
    }

    func unwrappedCard()->Card {
        if let wrapper = self as? CardWrapper {
            return wrapper.card
        }
        return self
    }
}
