import SwiftUI

extension Binding {
    func safelyUnwrapped<T>(_ defaultValue: T) -> Binding<T> where Value == Optional<T> {
        Binding<T> {
            wrappedValue ?? defaultValue
        } set: {
            guard wrappedValue != nil else { return }
            
            wrappedValue = $0
        }
    }
    
    func forceUnwrapped<T>() -> Binding<T> where Value == Optional<T> {
        Binding<T> {
            wrappedValue!
        } set: {
            wrappedValue = $0
        }
    }
}
