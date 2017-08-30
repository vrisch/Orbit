//
//  Orbit.swift
//  Orbit
//
//  Created by Vrisch on 2017-08-30.
//  Copyright © 2017 Orbit. All rights reserved.
//

import Foundation

public final class Disposable {
    public static let none = Disposable.init()
    public static let dispose = Disposable.init(dispose:)

    
    public init() {
        self.dispose = nil
    }
    
    public init(dispose: @escaping () -> Void) {
        self.dispose = dispose
    }

    deinit {
        empty()
    }
    
    private let dispose: (() -> Void)?
}

public extension Disposable {
    
    public func empty() {
        dispose?()
    }
}
