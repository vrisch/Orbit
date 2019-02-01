import Foundation

public struct Warning {
    public let message: String
    public init(message: String) {
        self.message = message
    }
}

public struct Link: Codable, Hashable {
    public typealias Relation = Tagged<Link, String>
    
    public let rel: Relation
    public let href: URL
    
    public init(rel: Relation, href: URL) {
        self.rel = rel
        self.href = href
    }
}

extension Link {
    public var data: Data? {
        return try? Data(contentsOf: href)
    }
}

extension Tagged where Tag == Link, RawValue == String {
    public static var `self`: Link.Relation { return "self" }
}

public struct Index<T>: Codable {
    public typealias Identifier = Tagged<T, UUID>

    public let id: Identifier
    public let _link: Link?

    public init(id: Identifier, _link: Link? = nil) {
        self.id = id
        self._link = _link
    }
}

extension Index: Hashable {
    public static func == (lhs: Index, rhs: Index) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
