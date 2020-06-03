//
//  MarkDownReaderTests.swift
//  MarkNodeTests
//
//  Created by yangzexin on 2020/6/3.
//  Copyright © 2020 yangzexin. All rights reserved.
//

import XCTest
@testable import MarkNode

class MarkDownReaderTests: XCTestCase {
    
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
    
    func testReadMultiNodeMarkdownDocument() {
        let reader = TSMarkDownReader(urlString: "http://chemagui.com:8000/running-lean.md")
        reader.defaultTitleForRootNode = "RunningLean"
        let wrappedReader = SFWrappableServant(servant: reader)
        self.sf_send(wrappedReader?.sync(), success: { [weak reader] value in
            guard let node = value as? TSNode, let reader = reader else {
                XCTFail("Unexpected type found: \(value ?? "nil")")
                return
            }
            XCTAssert(node.title == reader.defaultTitleForRootNode, "Create root node for multinode document")
        }) { (error) in
            XCTFail("Error on reading markdown document: \(error!)")
        }
        print("Finish tests")
    }
    
    func testReadSingleRootDocument() {
        let reader = TSMarkDownReader(file: "demo.md")
        let wrappedReader = SFWrappableServant(servant: reader)
        self.sf_send(wrappedReader?.sync(), success: { value in
            guard let node = value as? TSNode else {
                XCTFail("Unexpected type found: \(value ?? "nil")")
                return
            }
            XCTAssert(node.title == "Intro", "Single Root Node document")
        }) { (err) in
            XCTFail("Error on reading document: \(err!)")
        }
    }
    
}
