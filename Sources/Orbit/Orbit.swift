import Foundation

public struct Link: Codable, Hashable {
    public typealias Relation = Tagged<Link, String>
    
    public enum Method: String, Codable {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
    }
    
    public let rel: Relation
    public let href: URL
    public let method: Method
    
    public init(rel: Relation, href: URL, method: Method = .get) {
        self.rel = rel
        self.href = href
        self.method = method
    }
}

extension Tagged where Tag == Link, RawValue == String {
    public static var `self`: Link.Relation { return "self" }
}

public struct Index<T>: Codable {
    public typealias Identifier = Tagged<T, String>
    
    public let id: Identifier
    public let links: [Link]
    
    public init(id: Identifier, links: [Link] = []) {
        self.id = id
        self.links = links
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

public struct Response<T: Codable>: Codable {
    public let data: T
    
    public init(data: T) {
        self.data = data
    }
}

public struct Producing<Input, Output> {
    public let produce: (Input) -> Output
    
    public init(produce: @escaping (Input) -> Output) {
        self.produce = produce
    }
}
