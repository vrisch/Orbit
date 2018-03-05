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
        self.block = nil
        self.object = nil
        self.others = []
    }
    
    public init(block: @escaping () -> Void) {
        self.block = block
        self.object = nil
        self.others = []
    }
    
    public init(object: Any) {
        self.block = nil
        self.object = object
        self.others = []
    }

    deinit {
        empty()
    }

    var block: (() -> Void)?
    var object: Any?
    var others: [Disposables]
    weak var parent: Disposables?
}

public extension Disposables {

    public var isEmpty: Bool { return block == nil && others.count == 0 }

    public var count: Int {
        var result = 0
        if block != nil { result += 1 }
        if object != nil { result += 1 }
        others.forEach { result += $0.count }
        return result
    }

    public func empty() {
        block?()
        block = nil
        object = nil
        others.forEach { $0.empty() }
        others = []
    }

    public func add(disposable: Disposables) {
        guard disposable.parent == nil else { abort() }
        disposable.parent = self
        others.append(disposable)
    }

    public func add(disposables: [Disposables]) {
        disposables.forEach { add(disposable: $0) }
    }

    public func add(disposables: [Any]) {
        disposables.forEach { add(disposable: Disposables(object: $0)) }
    }

    static public func +=(lhs: inout Disposables, rhs: Disposables) {
        lhs.add(disposable: rhs)
    }

    static public func +=(lhs: inout Disposables, rhs: [Disposables]) {
        lhs.add(disposables: rhs)
    }

    static public func +=(lhs: inout Disposables, rhs: [Any]) {
        lhs.add(disposables: rhs)
    }
}

extension Disposables: CustomStringConvertible {

    public var description: String {
        return "Disposables: count=\(count)"
    }
}
