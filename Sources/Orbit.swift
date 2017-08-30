//
//  Orbit.swift
//  Orbit
//
//  Created by Vrisch on 2017-08-30.
//  Copyright © 2017 Orbit. All rights reserved.
//

import Foundation

public final class Disposable {

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

    private let block: (() -> Void)?
    private var object: Any?
    private var others: [Disposable]
    private weak var parent: Disposable?
}

public extension Disposable {

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
        object = nil
        others = []
    }

    public func add(disposable: Disposable) {
        guard disposable.parent == nil else { abort() }
        disposable.parent = self
        others.append(disposable)
    }

    public func add(disposables: [Disposable]) {
        disposables.forEach { add(disposable: $0) }
    }
    
    static public func +=(lhs: inout Disposable, rhs: Disposable) {
        lhs.add(disposable: rhs)
    }
    
    static public func +=(lhs: inout Disposable, rhs: [Disposable]) {
        lhs.add(disposables: rhs)
    }
}
