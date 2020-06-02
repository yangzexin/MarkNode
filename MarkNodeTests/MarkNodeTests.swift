//
//  MarkNodeTests.swift
//  MarkNodeTests
//
//  Created by yangzexin on 2020/5/30.
//  Copyright © 2020 yangzexin. All rights reserved.
//

import XCTest
@testable import MarkNode

class MarkNodeTests: XCTestCase {

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
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testStringFindMatching() {
        var attr = "link-node=http://www.test.com/link.md\n"
        var link = attr.findMatching(left: "link-node=", right: "\n")
        XCTAssert(link! == "http://www.test.com/link.md", "mismatched")
        attr = "link-node=http://www.test.com/link.md\nstyle=text-size: 18"
        link = attr.findMatching(left: "link-node=", right: "\n")
        XCTAssert(link! == "http://www.test.com/link.md", "mismatched")
    }
    
    func testGetLastPathComponent() {
        let attr = "http://www.test.com/link.md"
        let lastPathComponent = attr.lastPathComponent()
        XCTAssert(lastPathComponent == "link.md", "mismatched")
    }

}
