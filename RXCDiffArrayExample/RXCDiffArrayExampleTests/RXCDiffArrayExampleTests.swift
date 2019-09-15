//
//  RXCDiffArrayExampleTests.swift
//  RXCDiffArrayExampleTests
//
//  Created by ruixingchen on 9/15/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import XCTest
import Foundation

class RXCDiffArrayExampleTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
         let dataList = RXCDiffArray<[Card]>()
        let vc = ViewController()
        let entities = vc.randomEntities(countRange: 10000..<10001)
        let card = Card()
        card.elements = entities
        measure {
            let diff = dataList.batchWithDifferenceKit {
                dataList.contentCollection.append(card)
            }

        }
    }

}
