//
//  SimpleCard.swift
//  Example
//
//  Created by ruixingchen on 10/31/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import Foundation

class SimpleCard: Card {

    var entityType: String = "card"

    var entities: [Entity] = []

    var rda_diffableElements: [RDADiffableRowElementProtocol] {return self.entities}
    var rda_elements: [Any] {
        get {return self.entities}
        set {self.entities = newValue as! [Entity]}
    }
    var rda_diffIdentifier: AnyHashable {return self.entityType}
}
