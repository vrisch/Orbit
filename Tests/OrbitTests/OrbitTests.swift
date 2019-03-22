import Foundation
import XCTest

@testable import Orbit

enum TestError: Error {
    case failure
}

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
