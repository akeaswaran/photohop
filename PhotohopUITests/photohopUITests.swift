
//
//  photohopUITests.swift
//  photohopUITests
//
//  Created by Akshay Easwaran on 2/15/16.
//  Copyright © 2016 Akshay Easwaran. All rights reserved.
//

import XCTest

class photohopUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        continueAfterFailure = false

        
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func snapshotMainScreen() {
        snapshot("MainScreen")
    }
}
