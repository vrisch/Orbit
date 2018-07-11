//
//  FoundationExtensions.swift
//  Orbit
//
//  Created by Magnus on 2018-07-11.
//  Copyright © 2018 Orbit. All rights reserved.
//

#if canImport(Foundation)
import Foundation

extension Tagged where RawValue == UUID {
    init() {
        self.init(rawValue: UUID())
    }
}

extension Tagged where RawValue == String {
    init() {
        self.init(rawValue: UUID().uuidString)
    }
}

#endif
