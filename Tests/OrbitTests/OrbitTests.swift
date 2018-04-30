//
//  OrbitTests.swift
//  Orbit
//
//  Created by Vrisch on 2017-08-30.
//  Copyright © 2017 Orbit. All rights reserved.
//

import Foundation
import XCTest
import Orbit

class OrbitTests: XCTestCase {
    func test1() {
        var disposables = Disposables()
        XCTAssert(disposables.count == 0)
        XCTAssert(disposables.isEmpty)

        disposables += 1
        XCTAssert(disposables.count == 1)
        XCTAssert(!disposables.isEmpty)

        disposables += 2
        XCTAssert(disposables.count == 2)

        disposables.empty()
        XCTAssert(disposables.count == 0)
        XCTAssert(disposables.isEmpty)
    }
    
    static var allTests = [
        ("test1", test1),
    ]
}
