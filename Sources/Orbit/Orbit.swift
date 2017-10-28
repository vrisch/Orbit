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

    private var block: (() -> Void)?
    private var object: Any?
    private var others: [Disposables]
    private weak var parent: Disposables?
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
    
    static public func +=(lhs: inout Disposables, rhs: Disposables) {
        lhs.add(disposable: rhs)
    }
    
    static public func +=(lhs: inout Disposables, rhs: [Disposables]) {
        lhs.add(disposables: rhs)
    }
}
