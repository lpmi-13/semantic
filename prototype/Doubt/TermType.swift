/// The type of terms.
public protocol TermType {
	typealias Leaf

	var unwrap: Syntax<Self, Leaf> { get }
}


extension TermType {
	public static func unwrap(term: Self) -> Syntax<Self, Leaf> {
		return term.unwrap
	}

	/// Catamorphism over `TermType`s.
	///
	/// Folds the tree encoded by the receiver into a single value by recurring top-down through the tree, applying `transform` to leaves, then to branches, and so forth.
	public func cata<Result>(transform: Syntax<Result, Leaf> throws -> Result) rethrows -> Result {
		return try transform(unwrap.map { try $0.cata(transform) })
	}

	/// Paramorphism over `TermType`s.
	///
	/// Folds the tree encoded by the receiver into a single value by recurring top-down through the tree, applying `transform` to leaves, then to branches, and so forth. Each recursive instance is made available in the `Syntax` alongside the result value at that node.
	public func para<Result>(transform: Syntax<(Self, Result), Leaf> throws -> Result) rethrows -> Result {
		return try transform(unwrap.map { try ($0, $0.para(transform)) })
	}


	/// The count of nodes in the receiver.
	///
	/// This is used to compute the cost of patches, such that a patch inserting a very large tree will be charged approximately the same as a very large tree consisting of many small patches.
	public var size: Int {
		func size(term: Self) -> Int {
			switch term.unwrap {
			case .Leaf:
				return 1
			case let .Indexed(a):
				return a.reduce(0) { $0 + size($1) }
			case let .Fixed(a):
				return a.reduce(0) { $0 + size($1) }
			case let .Keyed(a):
				return a.reduce(0) { $0 + size($1.1) }
			}
		}
		return size(self)
	}
}


// MARK: - Equality

extension TermType {
	public static func equals(leaf: (Leaf, Leaf) -> Bool)(_ a: Self, _ b: Self) -> Bool {
		return Syntax.equals(leaf: leaf, recur: equals(leaf))(a.unwrap, b.unwrap)
	}
}


import Prelude