//
//  RDAEquatable.swift
//  RXCDiffArrayExample
//
//  Created by ruixingchen on 9/10/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import Foundation

///表示一个元素和另一个元素是否相等, 这里我们另起一个根协议, 是为了让实现者能够针对Diff做优化
///比如diff的时候,只要id相同我们就忽略其他,认为是相同的元素
public protocol RDAEquatable {

    func rda_isEqualTo(other object:Self)->Bool

}
