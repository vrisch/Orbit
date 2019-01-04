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

    func testSuccessfulPromising() {
        let expectation = XCTestExpectation(description: "")
        var result = 0

        let step1 = Promising<Void, Int> { _, fulfill in
            fulfill(42, nil)
        }
        let step2 = Promising<Int, Int> { value, fulfill in
            fulfill(value + value, nil)
        }
        let done = Promising<Int, Int> { value, fulfill in
            result = value
            fulfill(value, nil)
        }
        let fulfill = Promising<Void, Void> { _, fulfill in
            expectation.fulfill()
            fulfill((), nil)
        }

        step1.then(step2).then(done).always(fulfill).produce()

        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(result, 84)
    }

    func testFailingPromising() {
        let expectation = XCTestExpectation(description: "")
        var result = 0

        let step1 = Promising<Void, Int> { _, fulfill in
            fulfill(42, nil)
        }
        let step2 = Promising<Int, Int> { _, fulfill in
            fulfill(nil, TestError.failure)
        }
        let error = Promising<Error, Error> { value, fulfill in
            result = -1
            fulfill(value, nil)
        }
        let fulfill = Promising<Void, Void> { _, fulfill in
            expectation.fulfill()
            fulfill((), nil)
        }

        step1.then(step2).error(error).always(fulfill).produce()

        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(result, -1)
    }

    static var allTests = [
        ("test1", test1),
        ("testSuccessfulPromising", testSuccessfulPromising),
        ("testFailingPromising", testFailingPromising),
    ]
}
