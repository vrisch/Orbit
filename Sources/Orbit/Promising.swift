import Foundation

private let promisingQueue = DispatchQueue(label: "Promising")

public enum Outcome<Output> {
    case successful(Output)
    case invalid([Warning])
    case failed(Error)
    
    public func pass<T>() -> Outcome<T> {
        switch self {
        case .successful: fatalError()
        case let .invalid(warnings): return .invalid(warnings)
        case let .failed(error): return .failed(error)
        }
    }
}

public struct Promising<Input, Output> {
    public init(produce: @escaping (Input, @escaping (Outcome<Output>) -> Void) -> Void) {
        self.work = { outcome, fulfill in
            guard case let .successful(input) = outcome else { return fulfill(outcome.pass()) }
            produce(input, fulfill)
        }
    }

    public init(output: Output) {
        self.work = { _, fulfill in
            fulfill(.successful(output))
        }
    }

    public init(error: Error) {
        self.work = { _, fulfill in
            fulfill(.failed(error))
        }
    }

    public func produce(_ input: Input, fulfill: @escaping (Outcome<Output>) -> Void) {
        promisingQueue.async {
            self.work(.successful(input), fulfill)
        }
    }

    private init(work: @escaping (Outcome<Input>, @escaping (Outcome<Output>) -> Void) -> Void) {
        self.work = work
    }

    private let work: (Outcome<Input>, @escaping (Outcome<Output>) -> Void) -> Void
}

extension Promising where Input == Output {
    public init() {
        self.work = { outcome, fulfill in
            fulfill(outcome)
        }
    }
}

// CONTROL FLOW
extension Promising {
    public func then<Next>(_ next: Promising<Output, Next>) -> Promising<Input, Next> {
        return Promising<Input, Next> { input, fulfill in
            self.work(input) { output in
                next.work(output) { next in
                    fulfill(next)
                }
            }
        }
    }

    public func always(_ next: Promising<Void, Void>) -> Promising<Input, Void> {
        return Promising<Input, Void> { input, fulfill in
            self.work(input) { _ in
                // Always produce a Void value regardless of result from previous work
                next.work(.successful(())) { next in
                    fulfill(next)
                }
            }
        }
    }

    public func error(_ next: Promising<Error, Error>) -> Promising<Input, Output> {
        return Promising { input, fulfill in
            self.work(input) { output in
                // Only produce if error else fulfill
                guard case let .failed(error) = output else { return fulfill(output) }
                next.work(.successful(error)) { _ in
                    fulfill(.failed(error))
                }
            }
        }
    }
}

// BASE TRANSFORMATIONS
extension Promising {
    public func map<Next>(_ f: @escaping (Output) -> Next) -> Promising<Input, Next> {
        return Promising<Input, Next> { input, fulfill in
            self.produce(input) { output in
                guard case let .successful(value) = output else { return fulfill(output.pass()) }
                fulfill(.successful(f(value)))
            }
        }
    }

    public func flatMap<Next>(_ f: @escaping (Output) -> Promising<Input, Next>) -> Promising<Input, Next> {
        return Promising<Input, Next> { input, fulfill in
            self.produce(input) { output in
                guard case let .successful(value) = output else { return fulfill(output.pass()) }
                f(value).produce(input) { next in
                    fulfill(next)
                }
            }
        }
    }

    public func zip<Next>(_ next: Promising<Input, Next>) -> Promising<Input, (Output, Next)> {
        return Promising<Input, (Output, Next)>(produce: { input, fulfill in
            var o: Output? = nil
            var n: Next? = nil
            self.produce(input) { output in
                guard case let .successful(value) = output else { return fulfill(output.pass()) }
                o = value
                if let n = n { fulfill(.successful((value, n))) }
            }
            next.produce(input) { output in
                guard case let .successful(value) = output else { return fulfill(output.pass()) }
                n = value
                if let o = o { fulfill(.successful((o, value))) }
            }
        })
    }

    public func zip<A, B, C>(with f: @escaping (A, B) -> C) -> (Promising<Input, A>, Promising<Input, B>) -> Promising<Input, C> {
        return { $0.zip($1).map(f) }
    }

    // By providing (Int) -> String, transform Promising<String, URL> to Promising<Int, URL>
    public func pullback<A>(_ f: @escaping (A) -> Input) -> Promising<A, Output> {
        return Promising<A, Output> { input, fulfill in
            self.produce(f(input), fulfill: fulfill)
        }
    }
}

// ARRAY TRANSFORMATIONS
extension Promising {
    public func first<Element>() -> Promising<Input, Element?> where Output == [Element] {
        return Promising<Input, Element?> { input, fulfill in
            self.produce(input) { output in
                guard case let .successful(value) = output else { return fulfill(output.pass()) }
                fulfill(.successful(value.first))
            }
        }
    }

    public func map<Element, Next>(_ f: @escaping (Element) -> Next) -> Promising<Input, [Next]> where Output == [Element] {
        return Promising<Input, [Next]> { input, fulfill in
            self.produce(input) { output in
                guard case let .successful(value) = output else { return fulfill(output.pass()) }
                var result: [Next] = []
                value.forEach { element in
                    result.append(f(element))
                }
                fulfill(.successful(result))
            }
        }
    }

    public func flatMap<Element, Next>(_ f: @escaping (Element) -> Promising<Input, Next>) -> Promising<Input, [Next]> where Output == [Element] {
        return Promising<Input, [Next]> { input, fulfill in
            self.produce(input) { output in
                guard case let .successful(value) = output else { return fulfill(output.pass()) }
                guard !value.isEmpty else { return fulfill(.successful([])) }
                let count = value.count
                var result: [Next?] = Array(repeating: nil, count: count)
                Swift.zip(value.indices, value).forEach {
                    let (index, element) = $0
                    f(element).produce(input) { output in
                        guard case let .successful(value) = output else { return fulfill(output.pass()) }
                        result[index] = value
                        let ready = result.compactMap { $0 }
                        if ready.count == count { fulfill(.successful(ready)) }
                    }
                }
            }
        }
    }
}

// OPTIONAL TRANSFORMATIONS
extension Promising {
    public enum UnwrapError: Error {
        case valueIsNil
    }

    public func unwrap<Element>() -> Promising<Input, Element> where Output == Element? {
        return Promising<Input, Element> { input, fulfill in
            self.produce(input) { output in
                guard case let .successful(value) = output else { return fulfill(output.pass()) }
                guard let v = value else { return fulfill(.failed(UnwrapError.valueIsNil)) }
                fulfill(.successful(v))
            }
        }
    }
}

// TUPLE TRANSFORMATIONS
extension Promising {
    public func first<First, Second>() -> Promising<Input, First> where Output == (First, Second) {
        return Promising<Input, First> { input, fulfill in
            self.produce(input) { output in
                guard case let .successful(value) = output else { return fulfill(output.pass()) }
                fulfill(.successful(value.0))
            }
        }
    }
    
    public func second<First, Second>() -> Promising<Input, Second> where Output == (First, Second) {
        return Promising<Input, Second> { input, fulfill in
            self.produce(input) { output in
                guard case let .successful(value) = output else { return fulfill(output.pass()) }
                fulfill(.successful(value.1))
            }
        }
    }

    public func mapFirst<Element, Next, Second>(_ f: @escaping (Element) -> Next) -> Promising<Input, (Next, Second)> where Output == (Element, Second) {
        return Promising<Input, (Next, Second)> { input, fulfill in
            self.produce(input) { output in
                guard case let .successful(value) = output else { return fulfill(output.pass()) }
                fulfill(.successful((f(value.0), value.1)))
            }
        }
    }

    public func flatMapFirst<Element, Next, Second>(_ f: @escaping (Element) -> Promising<Input, Next>) -> Promising<Input, (Next, Second)> where Output == (Element, Second) {
        return Promising<Input, (Next, Second)> { input, fulfill in
            self.produce(input) { output1 in
                guard case let .successful(value1) = output1 else { return fulfill(output1.pass()) }
                f(value1.0).produce(input) { output2 in
                    guard case let .successful(value2) = output2 else { return fulfill(output2.pass()) }
                    fulfill(.successful((value2, value1.1)))
                }
            }
        }
    }

    public func mapSecond<Element, Next, First>(_ f: @escaping (Element) -> Next) -> Promising<Input, (First, Next)> where Output == (First, Element) {
        return Promising<Input, (First, Next)> { input, fulfill in
            self.produce(input) { output in
                guard case let .successful(value) = output else { return fulfill(output.pass()) }
                fulfill(.successful((value.0, f(value.1))))
            }
        }
    }

    public func flatMapSecond<Element, Next, First>(_ f: @escaping (Element) -> Promising<Input, Next>) -> Promising<Input, (First, Next)> where Output == (First, Element) {
        return Promising<Input, (First, Next)> { input, fulfill in
            self.produce(input) { output1 in
                guard case let .successful(value1) = output1 else { return fulfill(output1.pass()) }
                f(value1.1).produce(input) { output2 in
                    guard case let .successful(value2) = output2 else { return fulfill(output2.pass()) }
                    fulfill(.successful((value1.0, value2)))
                }
            }
        }
    }
}

// KEY PATH TRANSFORMATIONS
extension Promising {
    public func extract<Partial>(_ kp: KeyPath<Output, Partial>) -> Promising<Input, Partial> {
        return Promising<Input, Partial> { input, fulfill in
            self.produce(input) { output in
                guard case let .successful(value) = output else { return fulfill(output.pass()) }
                fulfill(.successful(value[keyPath: kp]))
            }
        }
    }
    
    public static func replace<Partial>(_ kp: WritableKeyPath<Output, Partial>) -> (Partial) -> Promising<Input, Output> where Input == Output {
        return { partial in
            return Promising<Input, Output>(produce: { input, fulfill in
                var value = input
                value[keyPath: kp] = partial
                fulfill(.successful(value))
            })
        }
    }
}

// Extras

public func start<Input, Output>(_ output: Output) -> Promising<Input, Output> {
    return Promising(output: output)
}

extension Promising where Input == Void {
    public func produce(fulfill: @escaping (Outcome<Output>) -> Void) {
        produce((), fulfill: fulfill)
    }
}

extension Promising where Input == Void, Output == Void {
    public func produce() {
        produce(()) { _ in }
    }
}

extension Promising {
    func delay(by duration: TimeInterval) -> Promising {
        return Promising { input, fulfill in
            self.produce(input) { output in
                promisingQueue.asyncAfter(deadline: .now() + duration) {
                    fulfill(output)
                }
            }
        }
    }
}
