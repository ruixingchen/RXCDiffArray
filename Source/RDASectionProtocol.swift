//
//  RDASectionProtocol.swift
//  RXCDiffArrayExample
//
//  Created by ruixingchen on 9/9/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import Foundation

///表示一个Section
public protocol RDASectionProtocol {

    associatedtype RDASectionIdentifierType: Hashable
//    typealias RDAElementIdentifierType = Hashable
    associatedtype RDAElementType: RDAElementProtocol

    var rda_sectionIdentifier: RDASectionIdentifierType {get}
    var rda_elements:[RDAElementType] {get set}

}

public protocol RDAElementProtocol {

    associatedtype RDAElementIdentifierType: Hashable

    var rda_elementIdentifier:RDAElementIdentifierType {get}

}
