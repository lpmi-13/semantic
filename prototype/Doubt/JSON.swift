public enum JSON {
	public typealias ArrayType = [Doubt.JSON]
	public typealias DictionaryType = [Swift.String:Doubt.JSON]

	case Number(Double)
	case Boolean(Bool)
	case String(Swift.String)
	case Array(ArrayType)
	case Dictionary(DictionaryType)
	case Null


	public var number: Double? {
		if case let .Number(d) = self { return d }
		return nil
	}

	public var boolean: Bool? {
		if case let .Boolean(b) = self { return b }
		return nil
	}

	public var string: Swift.String? {
		if case let .String(s) = self { return s }
		return nil
	}

	public var array: ArrayType? {
		if case let .Array(a) = self { return a }
		return nil
	}

	public var dictionary: DictionaryType? {
		if case let .Dictionary(d) = self { return d }
		return nil
	}

	public var isNull: Bool {
		if case .Null = self { return true }
		return false
	}

	public static let JSON: Prism<AnyObject, Doubt.JSON> = Prism(forward: toJSON, backward: toAnyObject)

	public static let number: Prism<Doubt.JSON, Double> = Prism(forward: { $0.number }, backward: { .Number($0) })
	public static let boolean: Prism<Doubt.JSON, Bool> = Prism(forward: { $0.boolean }, backward: { .Boolean($0) })
	public static let string: Prism<Doubt.JSON, Swift.String> = Prism(forward: { $0.string }, backward: { .String($0) })
	public static let array: Prism<Doubt.JSON, ArrayType> = Prism(forward: { $0.array }, backward: { .Array($0) })
	public static let dictionary: Prism<Doubt.JSON, DictionaryType> = Prism(forward: { $0.dictionary }, backward: { .Dictionary($0) })
}

public protocol JSONConvertible {
	init(JSON: Doubt.JSON)
	var JSON: Doubt.JSON { get }
}

extension JSON: JSONConvertible {
	public init(JSON: Doubt.JSON) {
		self = JSON
	}

	public var JSON: Doubt.JSON {
		return self
	}
}

extension JSONConvertible {
	static var JSONConverter: Prism<Self, Doubt.JSON> {
		return Prism(forward: { $0.JSON }, backward: { Self(JSON: $0) })
	}
}

extension Prism where To : JSONConvertible {
	public var number: Prism<From, Double> {
		return self >>> To.JSONConverter >>> Doubt.JSON.number
	}

	public var boolean: Prism<From, Bool> {
		return self >>> To.JSONConverter >>> Doubt.JSON.boolean
	}

	public var string: Prism<From, Swift.String> {
		return self >>> To.JSONConverter >>> Doubt.JSON.string
	}

	public var array: Prism<From, [Doubt.JSON]> {
		return self >>> To.JSONConverter >>> Doubt.JSON.array
	}

	public var dictionary: Prism<From, [String:Doubt.JSON]> {
		return self >>> To.JSONConverter >>> Doubt.JSON.dictionary
	}
}


private func toJSON(object: AnyObject) -> JSON? {
	struct E: ErrorType {}
	func die<T>() throws -> T {
		throw E()
	}
	do {
		switch object {
		case let n as Double:
			return JSON.Number(n)
		case let b as Bool:
			return JSON.Boolean(b)
		case let s as String:
			return JSON.String(s)
		case let a as [AnyObject]:
			return JSON.Array(try a.map { try toJSON($0) ?? die() })
		case let d as [String:AnyObject]:
			return JSON.Dictionary(Dictionary(elements: try d.map { ($0, try toJSON($1) ?? die()) }))
		case is NSNull:
			return JSON.Null
		default:
			return nil
		}
	} catch { return nil }
}

private func toAnyObject(json: JSON) -> AnyObject {
	switch json {
	case let .Number(n):
		return n
	case let .Boolean(b):
		return b
	case let .String(s):
		return s
	case let .Array(a):
		return a.map(toAnyObject)
	case let .Dictionary(d):
		return Dictionary(elements: d.map { ($0, toAnyObject($1)) })
	case .Null:
		return NSNull()
	}
}


import Foundation
