//
//  SimpleEntity.swift
//  Example
//
//  Created by ruixingchen on 10/31/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import Foundation

class SimpleEntity: Entity {

    var entityType: String = ""
    
    var rda_diffIdentifier: AnyHashable {return self.entityType}
}
