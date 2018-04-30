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
    }

    deinit {
        empty()
    }

    var objects: [Any] = []
}

public extension Disposables {

    public var count: Int { return objects.count }
    public var isEmpty: Bool { return objects.isEmpty }

    public func empty() {
        objects.removeAll()
    }

    public func add(disposable: Any) {
        objects.append(disposable)
    }

    public func add(disposables: [Any]) {
        objects += disposables
    }

    public func add(disposables: [Any]?) {
        guard let disposables = disposables else { return }
        add(disposables: disposables)
    }

    static public func +=(lhs: inout Disposables, rhs: Any) {
        lhs.add(disposable: rhs)
    }

    static public func +=(lhs: inout Disposables, rhs: [Any]) {
        lhs.add(disposables: rhs)
    }

    static public func +=(lhs: inout Disposables, rhs: [Any]?) {
        lhs.add(disposables: rhs)
    }
}

extension Disposables: CustomStringConvertible {

    public var description: String {
        return "Disposables: count \(count)"
    }
}
