//
//  Orbit.swift
//  Orbit
//
//  Created by Vrisch on 2017-08-30.
//  Copyright © 2017 Orbit. All rights reserved.
//

import Foundation

public final class Disposables {

    public init() {
        self.object = nil
        self.others = []
    }
    
    public init(object: Any) {
        self.object = object
        self.others = []
    }

    deinit {
        empty()
    }

    var object: Any?
    var others: [Disposables]
    weak var parent: Disposables?
}

public extension Disposables {

    public var isEmpty: Bool { return object == nil && others.count == 0 }

    public var count: Int {
        var result = 0
        if object != nil { result += 1 }
        others.forEach { result += $0.count }
        return result
    }

    public func empty() {
        object = nil
        others.forEach { $0.empty() }
        others = []
    }

    public func add(disposable: Any) {
        add(disposable: Disposables(object: disposable))
    }

    public func add(disposables: [Any]) {
        disposables.forEach { add(disposable: Disposables(object: $0)) }
    }

    public func add(disposable: Disposables) {
        guard disposable.parent == nil else { abort() }
        disposable.parent = self
        others.append(disposable)
    }

    static public func +=(lhs: inout Disposables, rhs: Any) {
        lhs.add(disposable: rhs)
    }

    static public func +=(lhs: inout Disposables, rhs: [Any]) {
        lhs.add(disposables: rhs)
    }
}

extension Disposables: CustomStringConvertible {

    public var description: String {
        return "Disposables: count \(count)"
    }
}
