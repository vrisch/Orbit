
public struct Promising<Input, Output> {
    public init(produce: @escaping (Input, @escaping (Output?, Error?) -> Void) -> Void) {
        self.work = { input, error, fulfill in
            guard let input = input else { return fulfill(nil, error) }
            produce(input, fulfill)
        }
    }

    public func produce(_ input: Input, fulfill: @escaping (Output?, Error?) -> Void) {
        work(input, nil, fulfill)
    }

    private init(work: @escaping (Input?, Error?, @escaping (Output?, Error?) -> Void) -> Void) {
        self.work = work
    }

    private let work: (Input?, Error?, @escaping (Output?, Error?) -> Void) -> Void
}

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
    public func map<A>(_ f: @escaping (Output) -> A) -> Promising<Input, A> {
        return Promising<Input, A> { input, fulfill in
            self.produce(input) { output, error in
                guard let output = output else { return fulfill(nil, error) }
                fulfill(f(output), nil)
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
    public func tupled() -> Promising<Input, (Output, Output)> {
        return Promising<Input, (Output, Output)> { input, fulfill in
            self.produce(input) { output, error in
                guard let output = output else { return fulfill(nil, error) }
                fulfill((output, output), nil)
            }
        }
    }
    
    public func first<A, B>() -> Promising<Input, A> where Output == (A, B) {
        return Promising<Input, A> { input, fulfill in
            self.produce(input) { output, error in
                guard let output = output else { return fulfill(nil, error) }
                fulfill(output.0, nil)
            }
        }
    }
    
    public func second<A, B>() -> Promising<Input, B> where Output == (A, B) {
        return Promising<Input, B> { input, fulfill in
            self.produce(input) { output, error in
                guard let output = output else { return fulfill(nil, error) }
                fulfill(output.1, nil)
            }
        }
    }
    
    public func mapFirst<A, B, C>(_ apply: Promising<A, C>) -> Promising<Input, (C, B)> where Output == (A, B) {
        return Promising<Input, (C, B)> { input, fulfill in
            self.produce(input) { output1, error in
                guard let output1 = output1 else { return fulfill(nil, error) }
                apply.produce(output1.0) { output2, error in
                    guard let output2 = output2 else { return fulfill(nil, error) }
                    fulfill((output2, output1.1), nil)
                }
            }
        }
    }
    
    public func mapSecond<A, B, C>(_ apply: Promising<B, C>) -> Promising<Input, (A, C)> where Output == (A, B) {
        return Promising<Input, (A, C)> { input, fulfill in
            self.produce(input) { output1, error in
                guard let output1 = output1 else { return fulfill(nil, error) }
                apply.produce(output1.1) { output2, error in
                    guard let output2 = output2 else { return fulfill(nil, error) }
                    fulfill((output1.0, output2), nil)
                }
            }
        }
    }
}

extension Promising where Input == Void, Output == Void {
    public func produce() {
        produce(()) { _, _ in }
    }
}
