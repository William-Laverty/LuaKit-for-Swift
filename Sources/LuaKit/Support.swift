//
//  Support.swift
//  Provides a WeakBox class for managing weak references.
//  Created by William Laverty on 14/12/2023.
//

import Foundation

/// Weak reference wrapper for managing weak references to AnyObject types.
public class WeakBox<Element> where Element: AnyObject {
    weak var element: Element?
    
    /// Initializes the WeakBox with an optional element.
    init(_ element: Element? = nil) {
        self.element = element
    }
}
