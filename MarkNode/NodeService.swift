//
//  NodeService.swift
//  MarkNode
//
//  Created by yangzexin on 2020/5/30.
//  Copyright © 2020 yangzexin. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

class NodeService: NSObject, NodeServiceType {
    func list() -> Observable<Result<[Node], Error>> {
        return Observable.create { observer -> Disposable in
            var nodes = [Node]()
            nodes.append(Node(title: "demo.md", storeType: .bundle, path: "demo.md"))
            nodes.append(Node(title: "about.md", storeType: .remote, path: "http://chemagui.com:8000/about.md"))
            nodes.append(Node(title: "running-lean.md", storeType: .remote, path: "http://chemagui.com:8000/running-lean.md"))
            observer.onNext(Result<[Node], Error>.success(nodes))
            observer.onCompleted()
            
            return Disposables.create {}
        }
    }
    
    func detail(_ node: Node) -> Observable<Result<TSNode, Error>> {
        let this = self
        return Observable.create { observer -> Disposable in
            var reader: TSMarkDownReader!
            switch node.storeType {
            case .bundle:
                reader = TSMarkDownReader(file: node.path)
            case .remote:
                reader = TSMarkDownReader(urlString: node.path)
            }
            let servant = SFWrappableServant(servant: reader)?.mainThreadFeedback()
            this.sf_send(servant, success: { node in
                observer.onNext(Result.success(node as! TSNode))
                observer.onCompleted()
            }, error: { err in
                observer.onError(err!)
            })
            
            return Disposables.create {
                servant!.cancel()
            }
        }
    }
}
