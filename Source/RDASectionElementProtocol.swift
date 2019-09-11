//
//  RDASectionElementProtocol.swift
//  RXCDiffArrayExample
//
//  Created by ruixingchen on 9/9/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import Foundation

///表示一个Section元素, 一般是一个容器元素, 这个元素有一些自己的属性, 同时包含了一组子元素集合(二维元素)
public protocol RDASectionElementProtocol  {

    ///子元素集合的类型
    associatedtype RDASectionElementsCollection: Collection

    ///这里需要setter为了方便在不可变对象的情况下操作第二维数据, 比如添加数据
    var rda_elements:RDASectionElementsCollection {get set}

}
