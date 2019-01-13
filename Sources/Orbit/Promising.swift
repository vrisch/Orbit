import Foundation

public struct Promising<Input, Output> {
    public init(produce: @escaping (Input, @escaping (Output?, Error?) -> Void) -> Void) {
        self.work = { input, error, fulfill in
            guard let input = input else { return fulfill(nil, error) }
            produce(input, fulfill)
        }
    }

    public init(output: Output) {
        self.work = { _, _, fulfill in
            fulfill(output, nil)
        }
    }

    public func produce(_ input: Input, fulfill: @escaping (Output?, Error?) -> Void) {
        promisingQueue.async {
            self.work(input, nil, fulfill)
        }
    }

    private init(work: @escaping (Input?, Error?, @escaping (Output?, Error?) -> Void) -> Void) {
        self.work = work
    }

    private let work: (Input?, Error?, @escaping (Output?, Error?) -> Void) -> Void
}

private let promisingQueue = DispatchQueue(label: "Promising")

extension Promising where Input == Output {
    public init() {
        self.work = { input, error, fulfill in
            guard let input = input else { return fulfill(nil, error) }
            fulfill(input, nil)
        }
    }
}

extension Promising {
    @available(*, deprecated, renamed: "then")
    public func append<Next>(_ next: Promising<Output, Next>) -> Promising<Input, Next> {
        return then(next)
    }

    public func then<Next>(_ next: Promising<Output, Next>) -> Promising<Input, Next> {
        return Promising<Input, Next> { input, error, fulfill in
            self.work(input, error) { output, error in
                next.work(output, error) { next, error in
                    fulfill(next, error)
                }
            }
        }
    }

    public func always(_ next: Promising<Void, Void>) -> Promising<Input, Void> {
        return Promising<Input, Void> { input, error, fulfill in
            self.work(input, error) { _, error in
                // Always produce a Void value regardless of result from previous work
                next.work((), error) { next, _ in
                    fulfill(next, nil)
                }
            }
        }
    }

    public func error(_ next: Promising<Error, Error>) -> Promising<Input, Output> {
        return Promising<Input, Output> { input, error, fulfill in
            self.work(input, error) { output, error in
                // Only produce if error else fulfill
                guard let error = error else { return fulfill(output, nil) }
                next.work(error, error) { _, error in
                    fulfill(nil, error)
                }
            }
        }
    }
}

extension Promising {
    public func map<Next>(_ f: @escaping (Output) -> Next) -> Promising<Input, Next> {
        return Promising<Input, Next> { input, fulfill in
            self.produce(input) { output, error in
                guard let output = output else { return fulfill(nil, error) }
                fulfill(f(output), nil)
            }
        }
    }
    
    public func flatMap<Next>(_ f: @escaping (Output) -> Promising<Input, Next>) -> Promising<Input, Next> {
        return Promising<Input, Next> { input, fulfill in
            self.produce(input) { output, error in
                guard let output = output else { return fulfill(nil, error) }
                f(output).produce(input) { next, error in
                    guard let next = next else { return fulfill(nil, error) }
                    fulfill(next, nil)
                }
            }
        }
    }
    
    public func zip<Next>(_ next: Promising<Input, Next>) -> Promising<Input, (Output, Next)> {
        return Promising<Input, (Output, Next)> { input, fulfill in
            var o: Output? = nil
            var n: Next? = nil
            self.produce(input) { value, error in
                guard let value = value else { return fulfill(nil, error) }
                o = value
                if let n = n { fulfill((value, n), nil) }
            }
            next.produce(input) { value, error in
                guard let value = value else { return fulfill(nil, error) }
                n = value
                if let o = o { fulfill((o, value), nil) }
            }
        }
    }

    // By providing (Int) -> String, transform Promising<String, URL> to Promising<Int, URL>
    public func pullback<A>(_ f: @escaping (A) -> Input) -> Promising<A, Output> {
        return Promising<A, Output> { input, fulfill in
            self.produce(f(input), fulfill: fulfill)
        }
    }
}

extension Promising {
    public func then<Element, Next>(_ next: Promising<Element, Next>) -> Promising<Input, [Next]> where Output == [Element] {
        return Promising<Input, [Next]> { input, fulfill in
            self.produce(input) { output, error in
                guard let output = output else { return fulfill(nil, error) }
                let count = output.count
                var result: [Next?] = Array(repeating: nil, count: count)
                Swift.zip(output.indices, output).forEach {
                    let (index, element) = $0
                    next.produce(element) { output, error in
                        guard let output = output else { return fulfill(nil, error) }
                        result[index] = output
                        let ready = result.compactMap { $0 }
                        if ready.count == count { fulfill(ready, nil) }
                    }
                }
            }
        }
    }

    public func map<Element, Next>(_ f: @escaping (Element) -> Next) -> Promising<Input, [Next]> where Output == [Element] {
        return Promising<Input, [Next]> { input, fulfill in
            self.produce(input) { output, error in
                guard let output = output else { return fulfill(nil, error) }
                var result: [Next] = []
                output.forEach { element in
                    result.append(f(element))
                }
                fulfill(result, nil)
            }
        }
    }

    public func flatMap<Element, Next>(_ f: @escaping (Element) -> Promising<Input, Next>) -> Promising<Input, [Next]> where Output == [Element] {
        return Promising<Input, [Next]> { input, fulfill in
            self.produce(input) { output, error in
                guard let output = output else { return fulfill(nil, error) }
                let count = output.count
                var result: [Next?] = Array(repeating: nil, count: count)
                Swift.zip(output.indices, output).forEach {
                    let (index, element) = $0
                    f(element).produce(input) { output, error in
                        guard let output = output else { return fulfill(nil, error) }
                        result[index] = output
                        let ready = result.compactMap { $0 }
                        if ready.count == count { fulfill(ready, nil) }
                    }
                }
            }
        }
    }
}

extension Promising {
    public func first<First, Second>() -> Promising<Input, First> where Output == (First, Second) {
        return Promising<Input, First> { input, fulfill in
            self.produce(input) { output, error in
                guard let output = output else { return fulfill(nil, error) }
                fulfill(output.0, nil)
            }
        }
    }
    
    public func second<First, Second>() -> Promising<Input, Second> where Output == (First, Second) {
        return Promising<Input, Second> { input, fulfill in
            self.produce(input) { output, error in
                guard let output = output else { return fulfill(nil, error) }
                fulfill(output.1, nil)
            }
        }
    }

    public func thenFirst<Element, Next, Second>(_ next: Promising<Element, Next>) -> Promising<Input, (Next, Second)> where Output == (Element, Second) {
        return Promising<Input, (Next, Second)> { input, fulfill in
            self.produce(input) { output1, error in
                guard let output1 = output1 else { return fulfill(nil, error) }
                next.produce(output1.0) { output2, error in
                    guard let output2 = output2 else { return fulfill(nil, error) }
                    fulfill((output2, output1.1), nil)
                }
            }
        }
    }

    public func mapFirst<Element, Next, Second>(_ f: @escaping (Element) -> Next) -> Promising<Input, (Next, Second)> where Output == (Element, Second) {
        return Promising<Input, (Next, Second)> { input, fulfill in
            self.produce(input) { output, error in
                guard let output = output else { return fulfill(nil, error) }
                fulfill((f(output.0), output.1), nil)
            }
        }
    }

    public func flatMapFirst<Element, Next, Second>(_ f: @escaping (Element) -> Promising<Input, Next>) -> Promising<Input, (Next, Second)> where Output == (Element, Second) {
        return Promising<Input, (Next, Second)> { input, fulfill in
            self.produce(input) { output1, error in
                guard let output1 = output1 else { return fulfill(nil, error) }
                f(output1.0).produce(input) { output2, error in
                    guard let output2 = output2 else { return fulfill(nil, error) }
                    fulfill((output2, output1.1), nil)
                }
            }
        }
    }
    
    public func thenSecond<Element, Next, First>(_ next: Promising<Element, Next>) -> Promising<Input, (First, Next)> where Output == (First, Element) {
        return Promising<Input, (First, Next)> { input, fulfill in
            self.produce(input) { output1, error in
                guard let output1 = output1 else { return fulfill(nil, error) }
                next.produce(output1.1) { output2, error in
                    guard let output2 = output2 else { return fulfill(nil, error) }
                    fulfill((output1.0, output2), nil)
                }
            }
        }
    }

    public func mapSecond<Element, Next, First>(_ f: @escaping (Element) -> Next) -> Promising<Input, (First, Next)> where Output == (First, Element) {
        return Promising<Input, (First, Next)> { input, fulfill in
            self.produce(input) { output, error in
                guard let output = output else { return fulfill(nil, error) }
                fulfill((output.0, f(output.1)), nil)
            }
        }
    }

    public func flatMapSecond<Element, Next, First>(_ f: @escaping (Element) -> Promising<Input, Next>) -> Promising<Input, (First, Next)> where Output == (First, Element) {
        return Promising<Input, (First, Next)> { input, fulfill in
            self.produce(input) { output1, error in
                guard let output1 = output1 else { return fulfill(nil, error) }
                f(output1.1).produce(input) { output2, error in
                    guard let output2 = output2 else { return fulfill(nil, error) }
                    fulfill((output1.0, output2), nil)
                }
            }
        }
    }
}

extension Promising where Input == Void {
    public func produce(fulfill: @escaping (Output?, Error?) -> Void) {
        produce((), fulfill: fulfill)
    }
}

extension Promising where Input == Void, Output == Void {
    public func produce() {
        produce(()) { _, _ in }
    }
}

extension Promising {
    func delay(by duration: TimeInterval) -> Promising {
        return Promising { input, fulfill in
            self.produce(input) { output, error in
                promisingQueue.asyncAfter(deadline: .now() + duration) {
                    fulfill(output, error)
                }
            }
        }
    }
}
