//
//  Publisher+Extensions.swift
//  Staxa
//
//  Created by Jacob Andrean on 14/05/25.
//

import Combine

public extension Publisher {
    func sink(
        receiveValue: @escaping ((Output) -> Void),
        receiveError: ((Failure) -> Void)? = nil
    ) -> AnyCancellable {
        self.sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    receiveError?(error)
                }
            },
            receiveValue: receiveValue
        )
    }
    
    func weakAssign<Object: AnyObject>(
        to keyPath: ReferenceWritableKeyPath<Object, Output>,
        on object: Object
    ) -> AnyCancellable {
        sink { [weak object] value in
            object?[keyPath: keyPath] = value
        }
    }
}
