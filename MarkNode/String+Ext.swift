//
//  String+Ext.swift
//  MarkNode
//
//  Created by yangzexin on 2020/6/1.
//  Copyright © 2020 yangzexin. All rights reserved.
//

import Foundation

extension String {
    func findMatching(left: String, right: String) -> String? {
        if let range = self.range(of: left) {
            let start = range.upperBound
            if let range = self.range(of: right, options: [], range: range.upperBound..<self.endIndex, locale: Locale.current) {
                let sub = String(self[start..<range.lowerBound])
                return sub
            }
        }
        return nil
    }
    
    func lastPathComponent() -> String {
        if let range = self.range(of: "/", options: .backwards) {
            let sub = String(self[range.upperBound..<self.endIndex])
            return sub
        }
        return self
    }
}
