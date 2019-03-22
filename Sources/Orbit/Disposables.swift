import Foundation

public final class Disposables {
    
    public init() {
    }
    
    deinit {
        empty()
    }
    
    var objects: [Any] = []
}

public extension Disposables {
    
    var count: Int { return objects.count }
    var isEmpty: Bool { return objects.isEmpty }
    
    func empty() {
        objects.removeAll()
    }
    
    func add(disposable: Any) {
        objects.append(disposable)
    }
    
    func add(disposable: Any?) {
        guard let disposable = disposable else { return }
        objects.append(disposable)
    }
    
    func add(disposables: [Any]) {
        objects += disposables
    }
    
    func add(disposables: [Any?]) {
        disposables.forEach { add(disposable: $0) }
    }
    
    func add(disposables: [Any]?) {
        guard let disposables = disposables else { return }
        add(disposables: disposables)
    }
    
    func add(disposables: [Any?]?) {
        guard let disposables = disposables else { return }
        add(disposables: disposables)
    }
    
    static func +=(lhs: inout Disposables, rhs: Any) {
        lhs.add(disposable: rhs)
    }
    
    static func +=(lhs: inout Disposables, rhs: Any?) {
        lhs.add(disposable: rhs)
    }
    
    static func +=(lhs: inout Disposables, rhs: [Any]) {
        lhs.add(disposables: rhs)
    }
    
    static func +=(lhs: inout Disposables, rhs: [Any?]) {
        lhs.add(disposables: rhs)
    }
    
    static func +=(lhs: inout Disposables, rhs: [Any]?) {
        lhs.add(disposables: rhs)
    }
    
    static func +=(lhs: inout Disposables, rhs: [Any?]?) {
        lhs.add(disposables: rhs)
    }
}

extension Disposables: CustomStringConvertible {
    
    public var description: String {
        return "Disposables: count \(count)"
    }
}
