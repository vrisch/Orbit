public struct Tagged<Tag, RawValue> {
    public var rawValue: RawValue
    
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
}

extension Tagged: CustomStringConvertible {
    public var description: String {
        return String(describing: self.rawValue)
    }
}

extension Tagged: RawRepresentable {
}

extension Tagged where RawValue == String {
    public static var uuid: Tagged<Tag, String> {
        return Tagged<Tag, String>(rawValue: UUID().uuidString)
    }
}

extension Tagged: Comparable where RawValue: Comparable {
    public static func < (lhs: Tagged, rhs: Tagged) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

extension Tagged: Decodable where RawValue: Decodable {
    public init(from decoder: Decoder) throws {
        self.init(rawValue: try decoder.singleValueContainer().decode(RawValue.self))
    }
}

extension Tagged: Encodable where RawValue: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}

extension Tagged: Equatable where RawValue: Equatable {
    public static func == (lhs: Tagged, rhs: Tagged) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

extension Tagged: Error where RawValue: Error {
}

extension Tagged: ExpressibleByBooleanLiteral where RawValue: ExpressibleByBooleanLiteral {
    public typealias BooleanLiteralType = RawValue.BooleanLiteralType
    
    public init(booleanLiteral value: RawValue.BooleanLiteralType) {
        self.init(rawValue: RawValue(booleanLiteral: value))
    }
}

extension Tagged: ExpressibleByExtendedGraphemeClusterLiteral where RawValue: ExpressibleByExtendedGraphemeClusterLiteral {
    public typealias ExtendedGraphemeClusterLiteralType = RawValue.ExtendedGraphemeClusterLiteralType
    
    public init(extendedGraphemeClusterLiteral: ExtendedGraphemeClusterLiteralType) {
        self.init(rawValue: RawValue(extendedGraphemeClusterLiteral: extendedGraphemeClusterLiteral))
    }
}

extension Tagged: ExpressibleByFloatLiteral where RawValue: ExpressibleByFloatLiteral {
    public typealias FloatLiteralType = RawValue.FloatLiteralType
    
    public init(floatLiteral: FloatLiteralType) {
        self.init(rawValue: RawValue(floatLiteral: floatLiteral))
    }
}

extension Tagged: ExpressibleByIntegerLiteral where RawValue: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = RawValue.IntegerLiteralType
    
    public init(integerLiteral: IntegerLiteralType) {
        self.init(rawValue: RawValue(integerLiteral: integerLiteral))
    }
}

extension Tagged: ExpressibleByNilLiteral where RawValue: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self.init(rawValue: RawValue(nilLiteral: nilLiteral))
    }
}

extension Tagged: ExpressibleByStringLiteral where RawValue: ExpressibleByStringLiteral {
    public typealias StringLiteralType = RawValue.StringLiteralType
    
    public init(stringLiteral: StringLiteralType) {
        self.init(rawValue: RawValue(stringLiteral: stringLiteral))
    }
}

extension Tagged: ExpressibleByUnicodeScalarLiteral where RawValue: ExpressibleByUnicodeScalarLiteral {
    public typealias UnicodeScalarLiteralType = RawValue.UnicodeScalarLiteralType
    
    public init(unicodeScalarLiteral: UnicodeScalarLiteralType) {
        self.init(rawValue: RawValue(unicodeScalarLiteral: unicodeScalarLiteral))
    }
}

extension Tagged: LosslessStringConvertible where RawValue: LosslessStringConvertible {
    public init?(_ description: String) {
        guard let rawValue = RawValue(description) else { return nil }
        self.init(rawValue: rawValue)
    }
}

extension Tagged: Numeric where RawValue: Numeric {
    public typealias Magnitude = RawValue.Magnitude
    
    public init?<T>(exactly source: T) where T: BinaryInteger {
        guard let rawValue = RawValue(exactly: source) else { return nil }
        self.init(rawValue: rawValue)
    }
    
    public var magnitude: RawValue.Magnitude {
        return self.rawValue.magnitude
    }
    
    public static func + (lhs: Tagged<Tag, RawValue>, rhs: Tagged<Tag, RawValue>) -> Tagged<Tag, RawValue> {
        return self.init(rawValue: lhs.rawValue + rhs.rawValue)
    }
    
    public static func += (lhs: inout Tagged<Tag, RawValue>, rhs: Tagged<Tag, RawValue>) {
        lhs.rawValue += rhs.rawValue
    }
    
    public static func * (lhs: Tagged, rhs: Tagged) -> Tagged {
        return self.init(rawValue: lhs.rawValue * rhs.rawValue)
    }
    
    public static func *= (lhs: inout Tagged, rhs: Tagged) {
        lhs.rawValue *= rhs.rawValue
    }
    
    public static func - (lhs: Tagged, rhs: Tagged) -> Tagged<Tag, RawValue> {
        return self.init(rawValue: lhs.rawValue - rhs.rawValue)
    }
    
    public static func -= (lhs: inout Tagged<Tag, RawValue>, rhs: Tagged<Tag, RawValue>) {
        lhs.rawValue -= rhs.rawValue
    }
}

extension Tagged: Hashable where RawValue: Hashable {
    public var hashValue: Int {
        return self.rawValue.hashValue
    }
}

extension Tagged: SignedNumeric where RawValue: SignedNumeric {
}

#if canImport(Foundation)
import Foundation

extension Tagged where RawValue == UUID {
    public init() {
        self.init(rawValue: UUID())
    }
}

extension Tagged where RawValue == String {
    public init() {
        self.init(rawValue: UUID().uuidString)
    }
}

#endif
