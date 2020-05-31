//
//  NodeServiceType.swift
//  MarkNode
//
//  Created by yangzexin on 2020/5/30.
//  Copyright © 2020 yangzexin. All rights reserved.
//

import Foundation
import RxSwift

protocol NodeServiceType {
    func list() -> Observable<Result<[Node], Error>>
    func detail(_ node: Node) -> Observable<Result<TSNode, Error>>
}
