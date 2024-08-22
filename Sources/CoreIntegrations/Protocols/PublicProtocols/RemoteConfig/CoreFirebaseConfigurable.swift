
import Foundation
#if !COCOAPODS
import FirebaseIntegration
#endif

public protocol CoreFirebaseConfigurable: CaseIterable, FirebaseConfigurable {
    var boolValue: Bool { get }
    var activeForSources: [CoreUserSource] { get }
}
