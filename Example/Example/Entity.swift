//
//  Model.swift
//  Example
//
//  Created by ruixingchen on 10/31/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import Foundation

protocol Entity: RDADiffableRowElementProtocol {
    var entityType:String {get}
}

protocol Card: Entity, RDADiffableSectionElementProtocol {

    var entities:[Entity] {get}

}
