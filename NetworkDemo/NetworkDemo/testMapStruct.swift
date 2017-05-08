//
//  testMapStruct.swift
//  NetworkDemo
//
//  Created by sijiechen3 on 2017/5/4.
//  Copyright © 2017年 sijiechen3. All rights reserved.
//

import Foundation
import ObjectMapper

struct Son: Mappable {
    var name: String = ""
    var age: Int = 0
    
    init(name: String, age: Int) {
        self.name = name
        self.age = age
    }
    
    init?(map: Map) {
    
    }
    
    mutating func mapping(map: Map) {
        name <- map["son_name"]
        age  <- map["son_age"]
    }
}

struct Fa: Mappable {
    
    var sons: [Son] = []
    var name: String = ""
    
    init() {}
    
    init?(map: Map) { }

    mutating func mapping(map: Map) {
        name <- map["fa_name"]
        sons <- map["fa_sons"]
    }
}
