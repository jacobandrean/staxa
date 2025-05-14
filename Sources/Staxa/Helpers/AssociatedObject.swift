//
//  AssociatedObject.swift
//  Staxa
//
//  Created by Jacob Andrean on 18/03/25.
//

import Foundation

public final class AssociatedObject<T> {
    private let key = UnsafeRawPointer(Unmanaged.passUnretained(UUID().uuidString as NSString).toOpaque())
    private var storage: NSMapTable<AnyObject, AnyObject>?

    public enum StoragePolicy {
        /// Closures, primitive types, objects that should be retained
        case strong
        /// Delegates, cached objects, avoiding retain cycles
        case weak
    }

    private let policy: StoragePolicy

    public init(policy: StoragePolicy = .strong) {
        self.policy = policy
        if policy == .weak {
            storage = NSMapTable<AnyObject, AnyObject>(keyOptions: .weakMemory, valueOptions: .strongMemory)
        }
    }

    public func get(for object: AnyObject) -> T? {
        switch policy {
        case .strong:
            return objc_getAssociatedObject(object, key) as? T
        case .weak:
            return storage?.object(forKey: object) as? T
        }
    }

    public func set(_ value: T?, for object: AnyObject) {
        switch policy {
        case .strong:
            objc_setAssociatedObject(object, key, value, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        case .weak:
            if let value = value as AnyObject? {
                storage?.setObject(value, forKey: object)
            } else {
                storage?.removeObject(forKey: object)
            }
        }
    }
}
