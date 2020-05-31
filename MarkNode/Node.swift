//
//  Node.swift
//  MarkNode
//
//  Created by yangzexin on 2020/5/30.
//  Copyright © 2020 yangzexin. All rights reserved.
//

import Foundation

enum NodeStoreType {
    case bundle
    case remote
}

struct Node {
    let title: String
    let storeType: NodeStoreType
    let path: String
}
