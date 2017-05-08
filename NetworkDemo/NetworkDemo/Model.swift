//
//  Model.swift
//  TestAlamofire
//
//  Created by 田腾飞 on 2016/12/12.
//  Copyright © 2016年 田腾飞. All rights reserved.
//

import UIKit
import ObjectMapper

struct Model: Mappable {
    var category: String?
    var name: String?
    
    init?(map: Map) {
    }
    
    mutating func mapping(map: Map) {
        category    <- map["category"]
        name        <- map["name"]
    }
}

struct ResponseModel1: Mappable {
    var data: [Model]?
    init?(map: Map) {
    }
    
    mutating func mapping(map: Map) {
        data    <- map["data"]
    }
}

struct ResponseModel: Mappable {
    var data: ResponseModel1?
    
    init?(map: Map) {
    }
    mutating func mapping(map: Map) {
        data    <- map["data"]
    }
}
