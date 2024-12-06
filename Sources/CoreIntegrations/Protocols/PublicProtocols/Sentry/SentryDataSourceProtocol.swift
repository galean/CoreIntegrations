//
//  File.swift
//  
//
//  Created by Anatolii Kanarskyi on 22/8/24.
//

import Foundation

public protocol SentryDataSourceProtocol: AnyObject {
    var dsn: String { get }
    var debug: Bool { get }
    var tracesSampleRate: Float { get }
    var profilesSampleRate: Float { get }
    var shouldCaptureHttpRequests: Bool { get }
    var httpCodesRange: NSRange { get }
    var handledDomains:[String]? { get }
}

public extension SentryDataSourceProtocol {
    var tracesSampleRate: Float {
        return 1.0
    }
    
    var profilesSampleRate: Float {
        return 1.0
    }
    
    var shouldCaptureHttpRequests: Bool {
        return true
    }
    
    var httpCodesRange: NSRange {
        return NSMakeRange(202, 599)
    }
    
    var handledDomains:[String]? {
        return nil
    }
}
