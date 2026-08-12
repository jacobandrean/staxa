//
//  PublishedBinding.swift
//  Staxa
//
//  Created by Jacob Andrean on 21/07/25.
//

import Combine
import Foundation

// MARK: - PublishedBinding Property Wrappers
@propertyWrapper
public final class PublishedBinding<Value> {
    private let getter: () -> Value
    private let setter: (Value) -> Void
    private let publisher: AnyPublisher<Value, Never>

    public var wrappedValue: Value {
        get { getter() }
        set { setter(newValue) }
    }

    public var projectedValue: AnyPublisher<Value, Never> {
        publisher
    }

    /// Designated initializer
    public init(
        getter: @escaping () -> Value,
        setter: @escaping (Value) -> Void,
        publisher: AnyPublisher<Value, Never>
    ) {
        self.getter = getter
        self.setter = setter
        self.publisher = publisher
    }

    /// Convenience initializer from a `@Published`
    public convenience init<Root: AnyObject>(
        root: Root,
        keyPath: ReferenceWritableKeyPath<Root, Value>,
        publisher: AnyPublisher<Value, Never>
    ) {
        self.init(
            getter: { root[keyPath: keyPath] },
            setter: { root[keyPath: keyPath] = $0 },
            publisher: publisher
        )
    }

    /// Helper to modify the value
    public func update(_ block: (inout Value) -> Void) {
        var val = wrappedValue
        block(&val)
        wrappedValue = val
    }
}

// MARK: - PublishedBinding builder from Published and AnyPublisher

public extension Published.Publisher {
    func publishedBinding<Root: AnyObject>(
        _ root: Root,
        for keyPath: ReferenceWritableKeyPath<Root, Output>
    ) -> PublishedBinding<Output> {
        return PublishedBinding(
            root: root,
            keyPath: keyPath,
            publisher: self.eraseToAnyPublisher()
        )
    }
}

public extension AnyPublisher where Failure == Never {
    func publishedBinding<Root: AnyObject>(
        _ root: Root,
        for keyPath: ReferenceWritableKeyPath<Root, Output>
    ) -> PublishedBinding<Output> {
        return PublishedBinding(
            root: root,
            keyPath: keyPath,
            publisher: self
        )
    }
}

// MARK: - PublishedBinding Builder for ObservableObject
public extension ObservableObject {
    func publishedBinding<Value>(
        _ valueKeyPath: ReferenceWritableKeyPath<Self, Value>,
        _ publisherKeyPath: KeyPath<Self, Published<Value>.Publisher>
    ) -> PublishedBinding<Value> {
        PublishedBinding(
            getter: { [weak self] in
                guard let self else { fatalError("self is deallocated") }
                return self[keyPath: valueKeyPath]
            },
            setter: { [weak self] in
                guard let self else { fatalError("self is deallocated") }
                self[keyPath: valueKeyPath] = $0
            },
            publisher: self[keyPath: publisherKeyPath].eraseToAnyPublisher()
        )
    }
}

// MARK: - Extensions

// MARK: - PublishedBinding builder for primitive value
public extension PublishedBinding {
    @available(*, deprecated, message: "initial is renamed to constant", renamed: "constant")
    static func initial(_ value: Value) -> PublishedBinding<Value> {
        let subject = CurrentValueSubject<Value, Never>(value)
        return PublishedBinding(
            getter: { subject.value },
            setter: { subject.send($0) },
            publisher: subject.eraseToAnyPublisher()
        )
    }
    
    static func constant(_ value: Value) -> PublishedBinding<Value> {
        let subject = CurrentValueSubject<Value, Never>(value)
        return PublishedBinding(
            getter: { subject.value },
            setter: { subject.send($0) },
            publisher: subject.eraseToAnyPublisher()
        )
    }
}

// MARK: - Binding Mapping Helper
public extension PublishedBinding {
    func mapBinding<Mapped>(
        getter: @escaping (Value) -> Mapped,
        setter: @escaping (Mapped) -> Value
    ) -> PublishedBinding<Mapped> {
        /// capture `self` strongly via `source` to avoid weakly-lived closures
        let source = self
        
        return PublishedBinding<Mapped>(
            getter: { getter(source.wrappedValue) },
            setter: { source.wrappedValue = setter($0) },
            publisher: source.projectedValue
                .map(getter)
                .eraseToAnyPublisher()
        )
    }
    
    func computed<Mapped>(getter: @escaping (Value) -> Mapped) -> PublishedBinding<Mapped> {
        /// capture `self` strongly via `source` to avoid weakly-lived closures
        let source = self
        
        return PublishedBinding<Mapped>(
            getter: { getter(source.wrappedValue) },
            setter: { _ in },
            publisher: source.projectedValue
                .map(getter)
                .eraseToAnyPublisher()
        )
    }
}

// MARK: - Binding Mapper from Generic Value to Optional<String>
public extension PublishedBinding where Value: OptionalConvertible {
    /// Binding mapper from generic Value to `Optional<String>`
    func asOptionalString(
        _ parse: @escaping (String?) -> Value.Wrapped?
    ) -> PublishedBinding<String?> {
        mapBinding(
            getter: { $0.asOptional.asString },
            setter: { str in Value(parse(str)) }
        )
    }
}

// MARK: - PublishedBinding<String?> builder for Int and Optional<Int>
public extension PublishedBinding where Value: OptionalConvertible, Value.Wrapped == Int {
    /// Creates a PublishedBinding<String?> from Value
    @available(*, deprecated, message: "please utilize mapBinding for better stability and robustness")
    var stringBinding: PublishedBinding<String?> {
        .init(
            getter: { [weak self] in
                guard let self, let unwrapped = wrappedValue.asOptional else { return nil }
                return "\(unwrapped)"
            },
            setter: { [weak self] in
                self?.wrappedValue = Value(Int($0 ?? "0") ?? 0)
            },
            publisher: projectedValue
                .map {
                    guard let unwrapped = $0.asOptional else { return nil }
                    return "\(unwrapped)"
                }
                .eraseToAnyPublisher()
        )
    }
}

// MARK: - PublishedBinding<String?> builder for Decimal and Optional<Decimal>
//public extension PublishedBinding where Value: OptionalConvertible, Value.Wrapped == Decimal {
//    var stringBinding: PublishedBinding<String?> {
//        /// if you are going to create reusable binding mapper with pre-processing on getter and setter
//        /// Otherwise just use mapBinding in the end-user level
//        mapBinding(
//            getter: { value in
//
//            },
//            setter: { mapped in
//
//            }
//        )
//    }
//}

// MARK: Convert Value → Optional<String>
private extension OptionalConvertible {
    /// Convert Value → String?
    var asString: String? {
        guard let unwrapped = asOptional else { return nil }
        return "\(unwrapped)"
    }
}

// TODO: move to new file if the extension getting bigger
public protocol OptionalConvertible {
    associatedtype Wrapped
    var asOptional: Wrapped? { get }
    init(_ some: Wrapped?)
}

extension Optional: OptionalConvertible {
    public var asOptional: Wrapped? { self }
    public init(_ some: Wrapped?) { self = some }
}

extension Int: OptionalConvertible {
    public var asOptional: Int? { self }
    public init(_ some: Int?) { self = some ?? 0 }
}

extension Decimal: OptionalConvertible {
    public var asOptional: Decimal? { self }
    public init(_ some: Decimal?) { self = some ?? 0 }
}

