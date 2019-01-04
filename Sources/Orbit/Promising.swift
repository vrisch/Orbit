
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

extension Promising where Input == Void, Output == Void {
    public func produce() {
        produce(()) { _, _ in }
    }
}
