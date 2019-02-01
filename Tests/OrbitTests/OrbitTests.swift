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
            fulfill(.successful(42))
        }
        let step2 = Promising<Int, Int> { value, fulfill in
            fulfill(.successful(value + value))
        }
        let done = Promising<Int, Int> { value, fulfill in
            result = value
            fulfill(.successful(value))
        }
        let fulfill = Promising<Void, Void> { _, fulfill in
            expectation.fulfill()
            fulfill(.successful(()))
        }

        step1.then(step2).then(done).always(fulfill).produce()

        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(result, 84)
    }

    func testFailingPromising() {
        let expectation = XCTestExpectation(description: "")
        var result = 0

        let step1 = Promising<Void, Int> { _, fulfill in
            fulfill(.successful(42))
        }
        let step2 = Promising<Int, Int> { _, fulfill in
            fulfill(.failed(TestError.failure))
        }
        let error = Promising<Error, Error> { value, fulfill in
            result = -1
            fulfill(.successful(value))
        }
        let fulfill = Promising<Void, Void> { _, fulfill in
            expectation.fulfill()
            fulfill(.successful(()))
        }

        step1.then(step2).error(error).always(fulfill).produce()

        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(result, -1)
    }

    func testMapPromising() {
        let expectation = XCTestExpectation(description: "")
        var result = 0
        
        let step1 = Promising<Void, Int> { _, fulfill in
            fulfill(.successful(42))
        }
        let done = Promising<Int, Int> { value, fulfill in
            result = value
            fulfill(.successful(value))
        }
        let fulfill = Promising<Void, Void> { _, fulfill in
            expectation.fulfill()
            fulfill(.successful(()))
        }
        
        let mapped = step1.map { $0 + $0 }

        mapped.then(done).always(fulfill).produce()
        
        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(result, 84)
    }

    func testFlatMapPromising() {
        let expectation = XCTestExpectation(description: "")
        var result = 0
        
        let step1 = Promising<Void, Int> { _, fulfill in
            fulfill(.successful(42))
        }
        let done = Promising<Int, Int> { value, fulfill in
            result = value
            fulfill(.successful(value))
        }
        let fulfill = Promising<Void, Void> { _, fulfill in
            expectation.fulfill()
            fulfill(.successful(()))
        }

        let mapped = step1.flatMap { Promising(output: $0 + $0).delay(by: 0.5).then(done).always(fulfill) }

        mapped.produce()
        
        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(result, 84)
    }

    func testZipPromising() {
        let expectation = XCTestExpectation(description: "")
        expectation.expectedFulfillmentCount = 2
        var result1 = 0
        var result2 = ""

        let step1 = Promising<Void, Int> { _, fulfill in
            fulfill(.successful(42))
        }
        let step2 = Promising<Void, String> { _, fulfill in
            fulfill(.successful("42"))
        }
        let done1 = Promising<Int, Int> { value, fulfill in
            result1 = value
            fulfill(.successful(value))
        }
        let done2 = Promising<String, String> { value, fulfill in
            result2 = value
            fulfill(.successful(value))
        }
        let fulfill = Promising<Void, Void> { _, fulfill in
            expectation.fulfill()
            fulfill(.successful(()))
        }
        
        let s1 = step1.then(done1).delay(by: 0.5).always(fulfill)
        let s2 = step2.then(done2).delay(by: 0.5).always(fulfill)

        s1.zip(s2).produce() { _ in }

        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(result1, 42)
        XCTAssertEqual(result2, "42")
    }

    func testZipSelfPromising() {
        let expectation = XCTestExpectation(description: "")
        var result = (0, 0)
        
        let step1 = Promising<Void, Int> { _, fulfill in
            fulfill(.successful(42))
        }
        let done = Promising<(Int, Int), (Int, Int)> { value, fulfill in
            result = value
            fulfill(.successful(value))
        }
        let fulfill = Promising<Void, Void> { _, fulfill in
            expectation.fulfill()
            fulfill(.successful(()))
        }

        step1.zip(step1).then(done).always(fulfill).produce() { _ in }

        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(result.0, 42)
        XCTAssertEqual(result.1, 42)
    }

    func testMapArrayPromising() {
        let expectation = XCTestExpectation(description: "")
        var result: [Int] = []
        
        let step1 = Promising<Void, [Int]> { _, fulfill in
            fulfill(.successful([42, 66]))
        }
        let done = Promising<[Int], [Int]> { value, fulfill in
            result = value
            fulfill(.successful(value))
        }
        let fulfill = Promising<Void, Void> { _, fulfill in
            expectation.fulfill()
            fulfill(.successful(()))
        }

        let mapped = step1.map { $0 + $0 }
        
        mapped.then(done).always(fulfill).produce()

        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(result, [84, 132])
    }

    func testFlatMapArrayPromising() {
        let expectation = XCTestExpectation(description: "")
        expectation.expectedFulfillmentCount = 2
        var result: [Int] = []

        let step1: Promising<Void, [Int]> = Promising(output: [42, 66])
        let done = Promising<Int, Int> { value, fulfill in
            result.append(value)
            fulfill(.successful(value))
        }
        let fulfill = Promising<Void, Void> { _, fulfill in
            expectation.fulfill()
            fulfill(.successful(()))
        }

        let mapped = step1.flatMap { Promising(output: $0 + $0).delay(by: 0.5).then(done).always(fulfill) }

        mapped.produce() { _ in }
        
        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(result, [84, 132])
    }

    static var allTests = [
        ("test1", test1),
        ("testSuccessfulPromising", testSuccessfulPromising),
        ("testFailingPromising", testFailingPromising),
        ("testMapPromising", testMapPromising),
        ("testFlatMapPromising", testFlatMapPromising),
        ("testZipPromising", testZipPromising),
        ("testZipSelfPromising", testZipSelfPromising),
        ("testMapArrayPromising", testMapArrayPromising),
        ("testFlatMapArrayPromising", testFlatMapArrayPromising),
    ]
}
